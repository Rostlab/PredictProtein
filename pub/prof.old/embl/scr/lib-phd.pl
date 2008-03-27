#!/usr/bin/perl
###! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				June,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.4   	May,    	1998	       #
#------------------------------------------------------------------------------#
#
# 
#===============================================================================
# subroutines   (internal):
# 
# 
#===============================================================================
# 
# subroutines   (external):
# 
#     lib-ut.pl       complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg,
#     lib-br.pl       convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,get_id,
#                     is_hssp_empty,is_rdb_acc,is_rdb_htm,is_rdb_sec,myprt_empty,
#                     myprt_txt,open_file,rd_rdb_associative,rdbphd_to_dotpred,wrt_phd2msf,
#     unk             abortProg,abortProgif,length,
#                     phd_htmfil'phd_htmfil,phd_htmisit'phd_htmisit,phd_htmref'phd_htmref,
#                     phd_htmtop'phd_htmtop,
# 
#===============================================================================
# 
# system calls:
# 
#     cp $para_ok_sec $tmp 
#     cp $para_ok_acc $tmp  
#     gunzip $tmp 
#     gunzip $tmp 
# 
#===============================================================================
# 
# 
# 
#===============================================================================
sub crossCpArchis {
    local ($para_ok_sec,$para_ok_acc,$optPhd,$dirPhdParaCross,$dirPhdNetCross) = @_;
    local ($tmp, $tmp_file, $tmp1, $tmp2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   crossCpArchis               copies architectures necessary according to fileIn
#-------------------------------------------------------------------------------
    if ( ! -e $fileIn ) {	# existence of file
	&myprt_empty; &myprt_txt("ERROR: \t file $fileIn does not exist"); 
	&abortProg; } 
				# ------------------------------
				# copy parameter files from origin
				# ------------------------------
    $Lacc=$Lsec=$Lhtm=0;
    $Lsec=1 if ($optPhd=~/both|3|sec/);
    $Lacc=1 if ($optPhd=~/both|3|acc|exp/);
    $Lhtm=1 if ($optPhd=~/htm/);
    if ($Lsec|$Lhtm) {
	if (! -e $para_ok_sec) { $tmp="$dirPhdParaCross"."$para_ok_sec";
				 $para_ok_sec=$tmp;}
	$tmp=$para_ok_sec;$tmp=~s/^.*\///g;
	$par{"paraHtmCross"}=$tmp if ($Lhtm);
	$par{"paraSecCross"}=$tmp if ($Lsec);
	push(@file_clean,"$tmp");
	if ( ! -e $tmp ) { 
	    print "crossCpArchis: system 'cp $para_ok_sec $tmp'\n";
	    system("cp $para_ok_sec $tmp"); }}
    if ($Lacc) {
	if (! -e $para_ok_acc) { $tmp="$dirPhdParaCross"."$para_ok_acc";
				 $para_ok_acc=$tmp;}
	$tmp=$para_ok_acc; $tmp=~s/^.*\///g;
	$par{"paraAccCross"}=$tmp;
	push(@file_clean,"$tmp");
	if ( ! -e $tmp ) { 
	    print "crossCpArchis: system 'cp $para_ok_sec $tmp'\n";
	    system("cp $para_ok_acc $tmp"); } }
				# ------------------------------
				# copy Networks for PHDsec/htm
    if ($Lsec|$Lhtm) {
	&open_file("FILEIN", "$para_ok_sec"); 
	while ( <FILEIN> ) { 
	    last if ($_=~/FILEARCHFST\(1:NUMNETFST\)/ ); }
	while ( <FILEIN> ) {
	    last if ( /^END/ );
	    next if ($_=~/^.FILE.+SND/ );
	    $tmp=$_; ($tmp1,$tmp2)=split(' ',$tmp,2);
	    $tmp2=~ s/\s|\n//g; $tmp="$tmp2" . ".z";
	    $tmp_file="$dirPhdNetCross" . "$tmp";
	    $tmp_file=~s/z$/gz/;$tmp=~s/z$/gz/
		if (! -e $tmp_file);
	    if (! -e $tmp_file) {
		print "*** ERROR cannot find '$tmp_file'\n";
		&abortProg; } 
	    if ( (-e $tmp) || (-e $tmp2) ) {
		print "--- assumed $tmp, up to date. If not: delete before start! \n"; }
	    else { 
		print "--- trying to copy:$tmp_file, to local:$tmp \n";
		system("\\cp $tmp_file* $tmp");
		print "--- trying to unzip:  $tmp\n";
		system("gunzip $tmp"); }
	    push(@file_clean,"$tmp2"); }
	close(FILEIN); }
				# ------------------------------
				# copy Networks for PHDacc
				# ------------------------------
    if ($Lacc) {
	&open_file("FILEIN", "$para_ok_acc"); 
	while ( <FILEIN> ) { 
	    last if ($_=~ /FILEARCHFST\(1:NUMNETFST\)/ ); }
	while ( <FILEIN> ) {
	    last if ($_=~ /^END/ );
	    next if ($_=~ /^.FILE.+SND/ );
	    $tmp=$_; ($tmp1,$tmp2)=split(' ',$tmp,2); 
	    $tmp2=~s/\s|\n//g; $tmp="$tmp2".".z";
	    $tmp_file = "$dirPhdNetCross"."$tmp";
	    $tmp_file=~s/z$/gz/;$tmp=~s/z$/gz/ if (! -e $tmp_file);
	    if (! -e $tmp_file) {
		print "*** ERROR cannot find '$tmp_file'\n";
		&abortProg; } 
	    if ( (-e $tmp) || (-e $tmp2) ) {
		print "--- assumed $tmp, up to date. If not: delete before start! \n"; }
	    else {
		print "--- trying to copy:$tmp_file, to local:$tmp \n";
		system("\\cp $tmp_file* $tmp");
		print "--- trying to unzip:  $tmp\n";
		system("gunzip $tmp"); }
	    push(@file_clean,"$tmp2"); }
	close(FILEIN);}
}				# end of crossCpArchis

#===============================================================================
sub crossListCheck {
    local ($pdb_in,$fileListTrain,
	   $dirPhdParaCross,$dirPhdNetCross,$fileHssp,$optPhd)= @_ ;
    local ($Lfound_one,$Lfound_here,$file_list,$tmp,$list_ok,$pdb_hit);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   crossListCheck              checks whether or not protein used for training
#-------------------------------------------------------------------------------
    if ($par{"verbose"}) {	# some talking to start with
	&myprt_line; &myprt_empty; 
	&myprt_txt("Sure you want to get a worse \(but cross-validated\) prediction ?"); 
	&myprt_txt("pdb in: \t \t $pdb_in"); 
	&myprt_txt("lists:  \t \t $fileListTrain");
	print "--- paths: \n"; 
	print "--- para cross:\t\t $dirPhdParaCross\n";
	print "--- archis:\t \t $dirPhdNetCross\n"; 
	print "--- lists: \t \t $dirPhdParaCross\n"; }
				# ------------------------------
				# consistency check: pdbid=4 letters?
    if ( (length($pdb_in) != 4) && ($pdb_in !~ /[0-9a-z]+_[0-9a-z]+/) ) {
	print "*** ERROR crossListCheck, you want cross-validation?\n";
	print "***       Then, supply a correct PDBid, '$pdb_in' is not appropriate!\n";
	&abortProg; } 
				# --------------------------------------------------
				# now checking the training lists
				# --------------------------------------------------
    ($list_ok,$para_ok_sec,$para_ok_acc)=
	&crossListIn($pdb_in,$fileListTrain,$optPhd);
    
    if ( $para_ok_sec !~ /def/ ) {
	if ($par{"verbose"}) {
	    print "--- ATTENTION: \t \t copying PHD architectures to local directory\n";
	    print "--- ATTENTION: \t \t make sure you have enough space!\n";}
	&crossCpArchis($para_ok_sec,$para_ok_acc,$optPhd,
		       $dirPhdParaCross,$dirPhdNetCross); }
    elsif ($par{"verbose"}) {
	&myprt_txt("no copying, standard PHD run, as protein not homologous!"); }
}				# end of crossListCheck

#===============================================================================
sub crossListIn {
    local ($pdb_in,$fileIn,$optPhd) = @_ ;
    local ($fhin,$fhinli,$Lfound_one,$Lfound_here,$file_list,
	   $tmp,$tmp1,$list_ok,$pdb_hit,$it);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   crossListIn                 checks whether or not protein in training list
#-------------------------------------------------------------------------------
    $fhin=  "FHIN_CROSSLISTIN";
    $fhinli="FHIN_CROSSLISTINLI";
#    $pdb_in =~ s/\s//g;  $search_pdbids="$pdb_in".","."$pdbids_in_hssp"; 
				# blabla
    if ($par{"verbose"}) {
	print "--- cross for PDBid \t '$pdb_in'\n"; }
				# existence
    if ( ! -e $fileIn ) {
	&myprt_empty; &myprt_txt("ERROR: \t cross-validation list $fileIn missing"); 
	&abortProg; } 
				# ----------------------------------------
				# read list
				# ----------------------------------------
    $Lok=$ct=0;
    &open_file("$fhin","$fileIn");
    while ( <$fhin> ) {
	last if ($Lok );
	$rd=$_;
	$rd=~s/\n//g; 
	next if ($rd=~/^\#/);	# do not read comment lines
	++$ct;
	$rd=~s/^[,\s\t]*|[,\s\t]$//g; 
	@tmp=split(/[, \t]+/,$rd);
	$file_list= "$dirPhdParaCross" . "$tmp[1]"; 
	print "--- now: \t \t '$file_list'\n" if ($par{"verbose"});

	$Lfound=0;
	&open_file("$fhinli","$file_list");
	while ( <$fhinli> ) {
	    $rd=~s/\n|\s//g; $rd=~tr/[A-Z]/[a-z]/; 
	    $tmp=$rd;
	    $tmp=substr($rd,1,4)  if ($optPhd !~ /^htm/);
	    next if ($pdb_in !~/$tmp/);
				# matching PDBid
	    $Lfound=1;
	    $pdb_hit=$tmp; 
	    print "--- hit: \t \t '$pdb_hit'\n" if ($par{"verbose"});
	    last; } close($fhinli);
	next if ($Lfound); 
	$Lok=1;
	$list_ok=$file_list;
	if ($ct==1) {
	    $para_ok_sec=$para_ok_acc="defaults"; 
	    next; }
	$para_ok_sec=$tmp[2];
	$para_ok_acc=$tmp[3]; } close($fhin);

				# ------------------------------
				# ERROR
    if (! $Lok ) {
	print "--- crossListIn: \t no list without current protein! \n";
	&abortProg;  }
				# ------------------------------
    if ($ct>1) {		# only if not defaults
	print 
	    "--- crossListIn: \t you can use the following list: \n",
	    "--- \t \t \t '$list_ok'\n",
	    "--- \t \t \t The list is copied to your local directory!\n"
		if ($par{"verbose"});
	$tmp=$list_ok; $tmp=~s/\n//g;$tmp=~s/.*\///g;
	($Lok,$msg)=
	    &sysCpfile($list_ok,$tmp);
	$list_ok=$tmp; }

    $para_ok_acc="unk"          if ($optPhd !~ /^htm/);

    return($list_ok,$para_ok_sec,$para_ok_acc);
}				# end of crossListIn

#===============================================================================
sub crossManager {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   crossManager                manages the cross-validation option
#      GLOBAL                   all
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."crossManager";$fhinLoc="FHIN"."$sbrName";

				# read id supplied in command line
    if ( ($par{"optPdbid"} ne "unk")&&(length($par{"optPdbid"})>1) ) {
	$pdb_in=$par{"optPdbid"}; }
    else {			# construct PDBid from input file name
	if (! $par{"optPhd"}=~/3|htm/) {
	    $pdb_in=$fileHssp;$pdb_in=~s/.*\/\W*//g;$pdb_in=~s/^(\w\w\w\w).+$/$1/; }
	else {
	    $pdb_in=$fileHssp; $pdb_in=~s/^.*\///g;
				# hack
	    if ($pdb_in =~ /_human|_mouse|_crigr/){
		$pdb_in=~s/^([0-9a-zA-Z]*_[0-9a-zA-Z]*).+$/$1/; }
	    elsif ($pdb_in =~ /^[0-9][0-9a-zA-Z]{3,3}[^0-9a-zA-Z]/) { # PDB id
		$pdb_in=~s/^(\w\w\w\w).+$/$1/; }
	    else { $pdb_in=~s/^([0-9a-zA-Z]*_[0-9a-zA-Z]*).+$/$1/; }} } # swissprot
    $pdb_in=~tr/[A-Z]/[a-z]/; $pdb_in=~s/\s|\n//g; # lower caps
    if ($par{"optPhd"}=~/3/) {
	print "*** ERROR: no cross-validation for all 3, thus specify as options\n",
	"***        on command line 'sec', 'acc', 'htm', or 'both'\n";
	&abortProg; }
				# check the architectures
    if ($par{"optPhd"}=~/htm/) { $fileListTrain=$par{"fileListTrainHtm"};}
    else { $fileListTrain=$par{"fileListTrainSecAcc"};}
    &crossListCheck($pdb_in,$fileListTrain,
		    $par{"dirPhdParaCross"},$par{"dirPhdNetCross"},
		    $fileHssp,$par{"optPhd"}); 
    return($pdb_in);
}				# end of crossManager

#===============================================================================
sub getInputPhd {
    local($fileInLoc,$formatLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getInputPhd                 converts the input file to HSSP format and filters
#       in:                     $fileInLoc,$formatLoc
#       out:                    $Lok,$msg,$file,$chain
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#-------------------------------------------------------------------------------
    $sbrName="getInputPhd";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!","","")         if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def formatLoc!","","")         if (! defined $formatLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!","","") if (! -e $fileInLoc);

    $doFilterHsspHtmLoc=$par{"doFilterHsspHtm"};
    $doFilterHsspHtmLoc=0       if ($par{"optPhd"} !~/3|htm/);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# format ok no filter: return
    return(1,"ok $sbrName",$fileInLoc,"","")   
	if ($formatLoc eq "HSSP"         && 
	    ! $par{"doFilterHssp"}       &&
	    ! $par{"doFilterHsspSafety"} &&
	    ! $doFilterHsspHtmLoc);
	    
				# ------------------------------
				# sequence formats: -> FASTA
				# ------------------------------
    if ($formatLoc eq "GCG"     || $formatLoc eq "SWISS"  || 
	$formatLoc =~ /^FASTA/i || $formatLoc =~ /^PIR/i  ||
	$formatLoc eq "SAF"     || $formatLoc eq "MSF"    ||
	$formatLoc eq "DSSP"    ) {

	$format=~tr/[A-Z]/[a-z]/; 
	$fileHssp=              $fileInLoc;$fileHssp=~s/\..*$/$par{"extHssp"}/;
	$fileHssp.=$par{"extHssp"}      if ($fileHssp eq $fileInLoc); # hack for SWISS-PROT
	$file{"convertHssp"}=   $fileHssp; 
	push(@kwdRm,"convertHssp")      if (! $par{"keepConvertHssp"});
	
        $cmd=                   $par{"exeCopf"}." ".$fileInLoc;
	$cmd.=                  " exeConvertSeq=".   $par{"exeConvertSeq"};
	$cmd.=                  " exeConvertSeqBig=".$par{"exeConvertSeq"};
#	$cmd.=                  " exeFssp2daf=".     $par{""};
	$cmd.=                  " exeConvHssp2saf=". $par{"exeConvHssp2saf"};
	$cmd.=                  " fileMatGcg=".      $par{"filterHsspMetric"};
#	$cmd.=                  " =".$par{""};
	$cmd.=                  " hssp fileOut=$fileHssp";
        eval                    "\$cmdSys=\"$cmd\"";
				# run PERL script conv_hssp2saf
        ($Lok,$msg)=            &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("conversion of $formatLoc $fileInLoc to HSSP",$msg),"","")
	    if (! $Lok); 
    }

				  # ------------------------------
    elsif ($formatLoc ne "HSSP"){ # unknown format
	return(&errSbr("currently 'only' conversion of MSF|SAF|FASTA|PIR|GCG|SWISS -> HSSP\n"),
	       "","");
    }

				# ------------------------------
				# HSSP input
    else {
	$fileHssp=$fileInLoc;}

				# **************************************************
				# correct input file?
				# **************************************************
    return("0","-*- WARN $sbrName: $fileHssp is empty\n","","") 
	if (&is_hssp_empty($fileHssp));


       				# ------------------------------
       				# filter if HSSP file too big
				#    (will crash in PHD)
       				# ------------------------------
    $doFilterHssp_iterate=0;
    if (defined $par{"doFilterHsspSafety"} &&
	$par{"doFilterHsspSafety"}){
	($Lok,$msg,$doFilterHssp_iterate)=
	    &getInputPhd_toobig($fileHssp,$doFilterHssp_iterate);
	return(&errSbrMsg("getInputPhd_toobig(".$fileHssp.",".$doFilterHssp_iterate.") (".
			  $fileHssp,$msg),"","")  
	    if (! $Lok);
    }

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok $sbrName",$fileHssp,$fileHssp) if (! $par{"doFilterHssp"}    && 
						    ! $doFilterHsspHtmLoc     && 
						    ! $doFilterHssp_iterate);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# --------------------------------------------------
				# filter HSSP file
				# --------------------------------------------------
    ($Lok,$msg,$fileHsspFilter,$fileHsspFilterHtm)=
	&getInputPhd_hsspfilter($fileHssp,$doFilterHssp_iterate,$doFilterHsspHtmLoc);

    return(&errSbrMsg("getInputPhd_hsspfilter() ($fileHssp->$fileHsspFilter",$msg))  
	if (! $Lok);
    
    return(1,"ok $sbrName",$fileHsspFilter,$fileHsspFilterHtm);
}				# end of getInputPhd

#===============================================================================
sub getInputPhd_hsspfilter {
    local($fileHsspLoc,$doFilterHssp_iterate,$doFilterHsspHtmLoc2) = @_ ;
    local($sbrName2,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getInputPhd_hsspfilter      filter HSSP file
#       in:                     $fileHsspLoc:          original HSSP file
#       in:                     $doFilterHssp_iterate: if 1: HSSP file too big,
#                                                      -> iterate filtering
#       out:                    1|0,msg,$fileHsspFilter,$fileHsspFilterHtm  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."getInputPhd_hsspfilter";
    $fhinLoc="FHIN_"."getInputPhd_hsspfilter";$fhoutLoc="FHOUT_"."getInputPhd_hsspfilter";

				# check arguments
    return(&errSbr("not def fileHsspLoc!",$sbrName2))    if (! defined $fileHsspLoc);
    return(&errSbr("not def doFilterHssp_iterate!",
		   $sbrName2))                           if (! defined $doFilterHssp_iterate);
    return(&errSbr("not def doFilterHsspHtmLoc2!",
		   $sbrName2))                           if (! defined $doFilterHsspHtmLoc2);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileHsspLoc!",$sbrName2)) if (! -e $fileHsspLoc);

				# --------------------------------------------------
				# hierarchy of events:
				# (1) try general, default filter (if option set)
				# (2) try redundancy 90,80,70,60,50: if still too big
				#     crash!
				# --------------------------------------------------

    $fileHssp2iterate=$fileHsspLoc;

				# (1) regular filter
    $Lonefilter_done_loc=0;
    if ($par{"doFilterHssp"}){
				# build up argument for calling hssp_filter

	@tmp=(
	      "packName=".     $par{"exeHsspFilterPack"},
	      "exeFilterHssp=".$par{"exeHsspFilter"},
	      "mode=ide",
	      "fileMatGcg=".   $par{"filterHsspMetric"},
	      );

	if (defined $par{"filterHsspVal"} && $par{"filterHsspVal"}) {
	    $val=$par{"filterHsspVal"} - 25;
	    push(@tmp,"thresh=$val");}
	if (defined $par{"optFilterHssp"}) {
	    $par{"optFilterHssp"}=~s/red\D*(\d+)/red=$1/;
	    push(@tmp,$par{"optFilterHssp"});}

	if    ($par{"debug"}){
	    push(@tmp," dbg");}
	elsif ($par{"verb"}){
	    push(@tmp," verb");}
	elsif (! $par{"verb2"}){
	    push(@tmp," noScreen");}

				# file names
	$fileHsspFilter=        $fileHsspLoc; $fileHsspFilter=~s/^.*\///g; 
	$fileHsspFilter=        $par{"dirWork"}.$fileHsspFilter."_filter";

	$file{"filterHssp"}=    $fileHsspFilter; 
	push(@kwdRm,"filterHssp")   if (! $par{"keepFilterHssp"});
	push(@tmp,"fileOut=".$fileHsspFilter);
				# calling external program
	$cmd=$par{"optNice"}." ".$par{"exeHsspFilterPl"}." ".$fileHsspLoc." ".join(' ',@tmp);
	print "$cmd\n";
	eval                    "\$cmdSys=\"$cmd\"";
				# run PERL script
	($Lok,$msg)=     
	    &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("filterHssp ($fileHsspLoc->$fileHsspFilter",$msg,$sbrName2))  
	    if (! $Lok);

	if (! -e $file{"filterHssp"}){
	    print "-*- WARN $sbrName: failed filtering $fileHsspLoc\n";
	    return(1,"almost ok $sbrName2",$fileHsspLoc);} 
	$fileHssp2iterate=$file{"filterHssp"};

				# do we still have to shrink or did that do it?
	if ($doFilterHssp_iterate){
	    ($Lok,$msg,$doFilterHssp_iterate)=
		&getInputPhd_toobig($fileHssp2iterate,$doFilterHssp_iterate);
	    return(&errSbrMsg("getInputPhd_toobig(".$fileHssp2iterate.",".
			      $doFilterHssp_iterate.") (".
			      $fileHssp2iterate,$msg,$sbrName2))  
		if (! $Lok);
	}
	$Lonefilter_done_loc=1;
    }

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# return if not too big or no flag
    return(1,"ok",$file{"filterHssp"},$file{"filterHssp"}) 
	if (! $doFilterHssp_iterate &&
	    ! $doFilterHsspHtmLoc2);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# --------------------------------------------------
				# (2) iteration over filter to reduce size!
				# --------------------------------------------------
    if ($doFilterHssp_iterate){

				# file names
	$fileHsspFilter=        $fileHssp; $fileHsspFilter=~s/^.*\///g; 
	$fileHsspFilter=        $par{"dirWork"}.$fileHsspFilter."_filter";
	$fileHsspFilterTmp=     $par{"dirWork"}.$fileHsspFilter."_tmp";
    
	$file{"filterHssp"}=      $fileHsspFilter; 
	push(@kwdRm,"filterHssp") if (! $par{"keepFilterHssp"});

				# build up argument for calling hssp_filter
	@tmp=(
	      "packName=".     $par{"exeHsspFilterPack"},
	      "exeFilterHssp=".$par{"exeHsspFilter"},
	      "mode=ide",
	      "fileMatGcg=".   $par{"filterHsspMetric"},
	      );

	if    ($par{"debug"}){
	    push(@tmp," dbg");}
	elsif ($par{"verb"}){
	    push(@tmp," verb");}
	elsif (! $par{"verb2"}){
	    push(@tmp," noScreen");}

	foreach $redloc (80,70,60,55,50,45,40,35,30){
	    
	    $file{"filterHssp".$redloc}=$fileHsspFilter."_red".$redloc; 
	    push(@kwdRm,"filterHssp".$redloc) if (! $par{"keepFilterHssp"});
				# argument for this run
	
	    $cmd= $par{"optNice"}." ".$par{"exeHsspFilterPl"};
	    $cmd.=" ".$fileHssp2iterate;
	    $cmd.=" fileOut=".$file{"filterHssp".$redloc};
	    $cmd.=" red=".$redloc;
	    $cmd.=" ".join(' ',@tmp);
	    
	    print "$cmd\n"          if ($par{"verb"});
	    
	    eval                    "\$cmdSys=\"$cmd\"";
				# run PERL script
	    ($Lok,$msg)=     
		&sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("filterHssp (iterate redloc=".
			      $redloc.", ".$fileHssp2iterate."->.".
			      $file{"filterHssp".$redloc},$msg,$sbrName2))  
		if (! $Lok);
	    $fileHssp2iterate=$file{"filterHssp".$redloc};

				# now ok? if so: leave
	    ($Lok,$msg,$doFilterHssp_iterate)=
		&getInputPhd_toobig($fileHssp2iterate,$doFilterHssp_iterate);
	    return(&errSbrMsg("getInputPhd_toobig(".$fileHssp2iterate.",".
			      $doFilterHssp_iterate.")",$msg,$sbrName2))  
		if (! $Lok);
	    last if (! $doFilterHssp_iterate);
	}

				# now copy the latest hypest to the file HSSPfilter
	$cmd="\\cp ".$fileHssp2iterate." ".$file{"filterHssp"};
				# run PERL script
	($Lok,$msg)=     
	    &sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("failed on simple copy: ".$fileHssp2iterate."->".
			  $file{"filterHssp"},$msg,$sbrName2))
	    if (! $Lok);
    }
    else {
	$fileHsspFilter=        $fileHssp; 
    }


    if ($doFilterHsspHtmLoc2){
				# build up argument for calling hssp_filter
	@tmp=(
	      "packName=".     $par{"exeHsspFilterPack"},
	      "exeFilterHssp=".$par{"exeHsspFilter"},
	      "mode=ide",
	      "fileMatGcg=".   $par{"filterHsspMetric"},
	      );

	if    ($par{"debug"}){
	    push(@tmp," dbg");}
	elsif ($par{"verb"}){
	    push(@tmp," verb");}
	elsif (! $par{"verb2"}){
	    push(@tmp," noScreen");}

				# file names
	$fileHsspFilterHtm=     $fileHsspLoc; $fileHsspFilterHtm=~s/^.*\///g; 
	$fileHsspFilterHtm=     $par{"dirWork"}.$fileHsspFilterHtm."_filterhtm";

	$file{"filterHsspHtm"}= $fileHsspFilterHtm; 
	push(@kwdRm,"filterHsspHtm")   if (! $par{"keepFilterHssp"});
	push(@tmp,"fileOut=".$fileHsspFilterHtm);
				# options
	$tmp=$par{"optFilterHsspHtm"};
	push(@tmp,"$tmp");
				# calling external program
	$fileInLoc=$fileHsspLoc;
	$fileInLoc=$file{"filterHssp"} if ($Lonefilter_done_loc);
	
	$cmd=$par{"optNice"}." ".$par{"exeHsspFilterPl"}." ".$fileInLoc." ".join(' ',@tmp);
	print "$cmd\n"          if ($par{"verb"});
	eval                    "\$cmdSys=\"$cmd\"";
				# run PERL script
	($Lok,$msg)=     
	    &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("filterHssp ($fileInLoc->$fileHsspFilterHtm",$msg,$sbrName2))  
	    if (! $Lok);

	if (! -e $file{"filterHsspHtm"}){
	    print "-*- WARN $sbrName: failed filtering $fileInLoc (for HTM)\n";
	    return(1,"almost ok $sbrName2",$fileInLoc);
	} 
    }
    else {
	$fileHsspFilterHtm=$fileHsspFilter;
    }

    return(1,"ok $sbrName2",$fileHsspFilter,$fileHsspFilterHtm);
}				# end of getInputPhd_hsspfilter

#===============================================================================
sub getInputPhd_toobig {
    local($fileHsspLoc2,$doFilterHssp_iterate) = @_ ;
    local($sbrName4,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getInputPhd_toobig          checks whether HSSP file too big for PHD reader
#       in:                     $fileHsspLoc2:          original HSSP file
#       in:                     $doFilterHssp_iterate: if 1: HSSP file too big,
#                                                      -> iterate filtering
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName4=$tmp."getInputPhd_toobig";
    $fhinLoc="FHIN_"."getInputPhd_toobig";$fhoutLoc="FHOUT_"."getInputPhd_toobig";
				# check arguments
    return(&errSbr("not def fileHsspLoc2!",$sbrName4))    if (! defined $fileHsspLoc2);
    return(&errSbr("not def doFilterHssp_iterate!",
		   $sbrName4))                           if (! defined $doFilterHssp_iterate);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileHsspLoc2!",$sbrName4)) if (! -e $fileHsspLoc2);

				# ------------------------------
				# now check HSSP file
				# ------------------------------
    $nali=$nres=0;
    open($fhinLoc,$fileHsspLoc2) || 
	return("0","*** $sbrName4 ERROR opening fileHsspLoc2=$fileHsspLoc2!\n");
    while(<$fhinLoc>){
	if    ($_=~/^SEQLENGTH\s+(\d+)/){
	    $nres=$1;}
	elsif ($_=~/^NALIGN\s+(\d+)/){
	    $nali=$1;
	    last;}
    }   
    close($fhinLoc);
    $prod=$nali*$nres;

    return(0,"*** $sbrName4 ERROR no 'SEQLENGTH DDDDD' given in fileHssp=$fileHsspLoc2\n")
	if (! defined $nres || ! $nres);
    return(0,"*** $sbrName4 ERROR no 'NALIGN DDDDD' given in fileHssp=$fileHsspLoc2\n")
	if (! defined $nali || ! $nali);
				# too large for HSSP reader in PHD_fortran 
    $doFilterHssp_iterate=0;
    $doFilterHssp_iterate=1
	if ($nali > $par{"maxhomFortran_maxnali"} || 
	    ($nres*$nali) > $par{"maxhomFortran_maxboth"});

    return(1,"ok $sbrName4",$doFilterHssp_iterate);
}				# end of getInputPhd_toobig

#===============================================================================
sub getFiles1Phd {
    local($fileIn,$chainIn)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFiles1Phd                builds command line input for calling phd.for
#       in/out GLOBAL:          ALL
#       out GLOBAL:             
#       out GLOBAL:             $FILE_PARA_SEC,$FILE_PARA_ACC,$FILE_PARA_HTM,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-phd:getFiles1Phd";
				# ------------------------------
				# output files
				# ------------------------------
    $id=
	&get_id($fileIn); $id=~s/^unk//g;
    $chain=""                   if ($chainIn =~ /^(unk| |\*)/ || 
				    length($chainIn)>1);
				# ------------------------------
				# intermediate title (needed for wrtRes1)
    $titleOne=$par{"title"};
    if ($#fileIn>1 && defined $chainIn && 
	length($chainIn)==1 && $chainIn ne " "){
	$titleOne=~s/ID/$id$chainIn/;}
    elsif ($#fileIn>1){
	$titleOne=~s/ID/$id/;}
				# ------------------------------
				# rename for input list (many input files)
                                # -> $file{"fileOutRdb"}
                                # -> $file{"fileOutPhd"}
				# ------------------------------
    foreach $kwd (@desFileOut){
	next if (! defined $par{$kwd} || !$par{$kwd});
	$file{$kwd}=$par{$kwd};
	if (defined $chainIn && length($chainIn)==1 && $chainIn ne " "){
	    $file{$kwd}=~s/ID/$id$chainIn/;
	    next; }
	$file{$kwd}=~s/ID/$id/;
    }
				# security
    $file{"fileNotHtm"}=0       if (! defined $file{"fileNotHtm"});

				# --------------------------------------------------
				# parameter files
				# --------------------------------------------------

				# sec
    if ($par{"optPhd"}=~/sec|3|both/){
	$FILE_PARA_SEC=
	    &getParaPhd1($par{"optIsCross"},$par{"paraSecCross"},
			 $par{"paraSec"},$par{"dirPhdNet"},$par{"dirWork"}); }
				# acc
    if ($par{"optPhd"}=~/acc|3|both/){
	$FILE_PARA_ACC=   
	    &getParaPhd1($par{"optIsCross"},$par{"paraAccCross"},
			 $par{"paraAcc"},$par{"dirPhdNet"},$par{"dirWork"}); }
				# htm
    if ($par{"optPhd"}=~/htm|3/){
	$FILE_PARA_HTM=   
	    &getParaPhd1($par{"optIsCross"},$par{"paraHtmCross"},
			 $par{"paraHtm"},$par{"dirPhdNet"},$par{"dirWork"}); }

    return(1,"ok $sbrName");
}				# getFiles1Phd

#===============================================================================
sub getParaPhd1 {
    local ($optIsCrossLoc,$paraFileCrossLoc,$paraFileLoc,$dirPhdNetLoc,$dirWorkLoc)=@_;
    local ($Lupdate,$fileParaTmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getParaPhd1                 gets local parameter file and updates it
#-------------------------------------------------------------------------------
    $SBR="lib-phd:getParaPhd1";
				# ------------------------------
				# ok already
    if ($optIsCrossLoc && -e $paraFileCrossLoc) { 
	$filePara=$paraFileCrossLoc; 
	return(1,"ok $SBR",$filePara); }

				# ------------------------------
				# update
    $filePara=$paraFileLoc;

    ($Lok,$msg,$fileParaTmp)=
	&getParaPhd1Update($filePara,$dirPhdNetLoc,$dirWorkLoc); 
    return(&errSbrMsg("no update of parameter file ($filePara)",$msg,$SBR),
	   $filePara)           if(! $Lok);

    if ( -e $fileParaTmp && $fileParaTmp ne $filePara ) { 
	$tmp=$fileParaTmp;$tmp=~s/^.*\///g;
	$filePara=$file{"para_"."$tmp"}=$fileParaTmp; 
	push(@kwdRm,"para_"."$tmp");}

    return (1,"ok $SBR",$filePara);
}				# end of getParaPhd1

#===============================================================================
sub getParaPhd1Update {
    local ($fileInLoc,$dirIn_net,$dirOut_net) = @_ ;
    local ($fhinLoc,$fhoutLoc,@line,$ftmp,$pathArch);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    getParaPhd1Update           local copy of PHD Para_file
#                               + change directory of architectures in that
#--------------------------------------------------------------------------------
    $SBR2="lib-phd:getParaPhd1Update";
				# defaults
    $fhinLoc=   "FHIN_getParaPhd1Update";
    $fhoutLoc=  "FHOUT_getParaPhd1Update";
    $ftmp=      $par{"titleTmp"}.$par{"jobid"}."_Para_phd.com";
    $fileIn_loc=$fileInLoc;	# copy to local ?
    $dirIn_net= &complete_dir($dirIn_net);
    $jobidLoc=  $par{"jobid"};
				# ------------------------------
    if ($fileInLoc=~/\//){	# get correct file
	if (  ((length($dirIn_net)>0) &&($fileInLoc!~/^$dirIn_net/)) ||
	      ((length($dirOut_net)>0)&&($fileInLoc!~/^$dirOut_net/)) ) {
	    $fileIn_loc=~s/^.*\///g;$tmp="$dirOut_net".$fileIn_loc;$fileIn_loc=$tmp;
	    $fileIn_loc=~s/[Pp]ara/Para_$jobidLoc/g;
	    if (! -e $fileIn_loc) {
		($Lok,$msg)=
		    &sysCpfile($fileInLoc,$fileIn_loc); 
		return(0,"*** ERROR $SBR2:\n".$msg) if (! $Lok);}}}

				# ------------------------------
				# add directory if parameter file not existing
    $fileIn_loc=$dirIn_net.$fileIn_loc if (! -e $fileIn_loc);
				# still not existing? -> error
    &abortProg("*** ERROR $SBR2: no parameter file '$fileIn_loc'!\n")
	if (! -e $fileIn_loc);
				# ------------------------------
				# read Para file content into array @line
    $Lok=&open_file("$fhinLoc", "$fileIn_loc");
         &abortProg("*** ERROR $SBR2: could not open old file '$fileIn_loc'!\n") if (! $Lok);
    $#line=0; undef $pathArch;
    while(<$fhinLoc>){ $rd=$_;
		       $pathArch=$rd if ($rd=~/^\s*PATH.*ARCH/);
		       push(@line,$rd); } close($fhinLoc);
    $pathArch=~s/^\s*PATHARCH//;$pathArch=~s/\s|\n//g if (defined $pathArch);
				# ------------------------------
				# write new output file if not same path
    return(1,"ok $SBR2",$fileIn_loc)
	if ($dirIn_net eq $pathArch );

    $Lok=&open_file("$fhoutLoc", ">$ftmp");
         &abortProg("*** ERROR $SBR2: could not open new file '$ftmp'!\n") if (! $Lok);
    foreach $line (@line) {
	if ($line !~/^\s*PATHARCH/){
	    print $fhoutLoc $line; }
	else {
	    $line=~s/^([^\/]*)\/.*$/$1$dirIn_net/;
	    print $fhoutLoc $line;}} close($fhoutLoc);
				# ------------------------------
				# move new to old
    ($Lok,$msg)=
	&sysMvfile($ftmp,$fileIn_loc);
    return(0,"*** ERROR $SBR2:\n".$msg) if (! $Lok);

    return(1,"ok $SBR2",$fileIn_loc);
}				# end of getParaPhd1Update

#===============================================================================
sub wrtList {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtList                     writes a list of RDB files for EVALSEC
#       out:                    1|0,msg,  implicit: list
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-phd:"."wrtList";$fhoutLoc="FHOUT_"."wrtList";

				# ------------------------------
				# temporary files
    foreach $kwd ("listTmp1","listTmp2","listTmp3") {
	push(@kwdRm,$kwd);
	$file{$kwd}=
	    $par{"dirWork"}.$par{"titleTmp"}.$par{"jobid"}.".$kwd";  }
    
				# ------------------------------
				# all RDB files
    $#tmp=0;
    foreach $file (@fileOutRdbOk){
	next if (! -e $file);
	push(@tmp,$file); }
				# ------------------------------
				# write to file temp1
				# open file
    &open_file("$fhoutLoc",$file{"listTmp1"}) || 
	return(&errSbr("fileOut=".$file{"listTmp1"}.", not opened"));
    foreach $file (@tmp){
	print $fhoutLoc "$file\n";}
    close($fhoutLoc);

    return(&errSbr("failed writing list_of_rdb to listTmp1=".$file{"listTmp1"}.",")) 
	if (! -e $file{"listTmp1"});
				# ------------------------------
				# sort PDBid
    if ($par{"doPrepevalSort"}){
	$cmd=$cmdSys="";
	$cmd=$par{"exePdbidSort"}." ".$file{"listTmp1"}." fileOut=".$file{"listTmp2"};
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=     
	    &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("exePdbidSort ($cmd)",$msg)) if (! $Lok);
	return(&errSbr("no output file listTmp2=".$file{"listTmp2"},$msg)) 
	    if (! -e $file{"listTmp2"}); }

				# ------------------------------
				# sec: PHD.rdb -> LIST.predrel
    if ($par{"doRdb2pred"}) {
	$cmd=$cmdSys="";
	$cmd=$par{"exeRdb2pred"}." ".$file{"listTmp2"}." fileOut=".$file{"listTmp3"};
				# sec
	if ($par{"optPhd"} =~/sec|both|3/) {
	    $cmd.=" sec";
	    eval "\$cmdSys=\"$cmd\"";
	    ($Lok,$msg)=
		&sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("exeRdb2pred, sec ($cmd)",$msg)) if (! $Lok);
	    return(&errSbr("no output file sec listTmp3=".$file{"listTmp3"},$msg)) 
		if (! -e $file{"listTmp3"}); 
	    ($Lok,$msg)=
		&sysMvfile($file{"listTmp3"},$par{"fileOutEvalsec"}); }

				# acc
	if ($par{"optPhd"} =~/acc|both|3/) {
	    $cmd.=" acc";
	    eval "\$cmdSys=\"$cmd\"";
	    ($Lok,$msg)=
		&sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("exeRdb2pred, acc ($cmd)",$msg)) if (! $Lok);
	    return(&errSbr("no output file acc listTmp3=".$file{"listTmp3"},$msg)) 
		if (! -e $file{"listTmp3"}); 
	    ($Lok,$msg)=
		&sysMvfile($file{"listTmp3"},$par{"fileOutEvalacc"}); }
				# htm
	if ($par{"optPhd"} =~/htm|3/) {
	    $cmd.=" htm";
	    eval "\$cmdSys=\"$cmd\"";
	    ($Lok,$msg)=
		&sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("exeRdb2pred, htm ($cmd)",$msg)) if (! $Lok);
	    return(&errSbr("no output file htm listTmp3=".$file{"listTmp3"},$msg)) 
		if (! -e $file{"listTmp3"}); 
	    ($Lok,$msg)=
		&sysMvfile($file{"listTmp3"},$par{"fileOutEvalacc"}); }
    }

    return(1,"ok $sbrName");
}				# end of wrtList

#===============================================================================
sub wrtRes1 {
    local ($protname) = @_ ;
    local ($fhin,$optPhd_loc,@file,$Lconv,$fhoutLoc,@optPhd_loc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtRes1                    writes the output files for one protein prediction
#--------------------------------------------------------------------------------
    $sbrName="wrtRes1"; $fhin= "FHIN_WRTRES1";$fhoutLoc="FHOUT_WRTRES1";
    $optPhd_loc=$par{"optPhd"};
    $#file=$#optPhd_loc=0;
    $Lconv=1;
    $filePhd=   $file{"fileOutPhd"};
    $fileRdb=   $file{"fileOutRdb"};
    if ($optPhd_loc ne "htm"){	# note: from lib-br:phdRun (yy) !!
	$filePhdTmp=$fileTmp{"$optPhd_loc","phd"};
	$fileRdbTmp=$fileTmp{"$optPhd_loc","rdb"}; }
    else {			# note: from lib-br:phdRun (yy) !!
	$filePhdTmp=$fileTmp{"$optPhd_loc","phd"};
	$fileRdbTmp=$fileTmp{"$optPhd_loc"."fin","rdb"}; }

				# --------------------------------------------------
				# if default option and no transmembrane region 
				# detected, change option!
				# --------------------------------------------------
                                # all 3= sec + acc + htm
    if ($optPhd_loc eq "3" && -e $par{"fileNotHtm"}) {
	print 
	    "-*- WARNING wrtRes1 changes option, as no transmembrane region detected:\n",
	    "-*-         '",$par{"fileNotHtm"},"'\n";
	$optPhd_loc="both";}
                                # for PHDsec + PHDacc
    if   ($optPhd_loc eq "both"){
	push(@optPhd_loc,"sec","acc");
	push(@file,             # note: from lib-br:phdRun (yy) !!
             $fileTmp{"sec","rdb"},$fileTmp{"acc","rdb"}); }
                                # for PHDsec,acc,htm
    elsif($optPhd_loc eq "3"){
	push(@optPhd_loc,"sec","acc","htm");
	push(@file,             # note: from lib-br:phdRun (yy) !!
             $fileTmp{"sec","rdb"},$fileTmp{"acc","rdb"},$fileTmp{"htmfin","rdb"}); }
				# for PHDhtm get filter stuff from RDB
    elsif($optPhd_loc eq "htm"){
	push(@optPhd_loc,"htm");
	push(@file,		# note: from lib-br:phdRun (yy) !!
             $fileTmp{"htmfin","rdb"}); }
    else {
	$Lconv=0;}

				# --------------------------------------------------
    if (! $Lconv) {		# simply copy
				# --------------------------------------------------
	($Lok,$msg)=
            &sysCpfile($filePhdTmp,$filePhd) if ($filePhd ne "unk" && length($filePhd)>1 );
        return(&errSbrMsg("pred file NN ($filePhdTmp)!",$msg),0) if (! $Lok);

	($Lok,$msg)=
            &sysCpfile($fileRdbTmp,$fileRdb) if ($fileRdb ne "unk" && length($fileRdb)>1);
        return(&errSbrMsg("pred file NN ($fileRdbTmp)!",$msg),0) if (! $Lok);

                                # ------------------------------
                                # everything fine -> return
                                # ------------------------------
        push(@fileOutPhdOk,$filePhd) if (-e $filePhd);
        push(@fileOutRdbOk,$fileRdb) if (-e $fileRdb);
        return(1,"ok $sbrName"); }
        
				# --------------------------------------------------
                                # RDB -> .phd files
				# --------------------------------------------------
    &open_file("$fhoutLoc",">$filePhd") || 
        return(&errSbr("failed creating filePhd=$filePhd"),0);
				# ------------------------------
				# read quotes
    if (-e $par{"headPhdConcise"}) {
        $Lok=&open_file("$fhin",$par{"headPhdConcise"});
	if ($Lok) {
	    while(<$fhin>){
		print $fhoutLoc $_;}
	    close($fhin);}}
				# ------------------------------
				# read headers 
    print $fhoutLoc "*"," " x 74,"*\n"; 
    $des_phd=$optPhd_loc[1];

    @des_key=("Some statistics","PHD output for your protein",
              "About the protein","WARNING");
    if (! -e $fileTmp{"$des_phd","phd"}){
        print 
            "*** ERROR wrtRes1: for protname=$protname, ",
            "des_phd=$des_phd, no file=",$fileTmp{"$des_phd","phd"},"!!\n";}
    else{
        foreach $des_key(@des_key){
            @rd=&wrtRes1merde1($fileTmp{"$des_phd","phd"},$des_key);
            next if ($#rd == 0);
            print $fhoutLoc "*"x 76,"\n","*"," " x 74,"*\n" 
                if ($des_key ne $des_key[1]);
            &wrtRes1merde2($fhoutLoc,$des_phd,$des_key,@rd); 
            print $fhoutLoc "*"," " x 74,"*\n"; }}
				# ------------------------------
				# read abbreviations
    $desTmp=substr($optPhd_loc,1,1);
    $desTmp=~tr/[a-z]/[A-Z]/;
    $desTmp.=substr($optPhd_loc,2);
	
    $des="abbrPhd".$desTmp;$fileTmp=$par{$des};
    if (-e $fileTmp) {
        $Lok=&open_file("$fhin","$fileTmp");
	if ($Lok){
	    while(<$fhin>){
		next if ( $optPhd_loc eq "htm" && $par{"optDoHtmref"} && $par{"optDoHtmtop"});
		print $fhoutLoc $_;}
	    close($fhin); }}
				# ------------------------------
				# final 'protein name, length'
    $des_phd=$optPhd_loc[1];
    $des_key=("protein");
    if (! -e $fileTmp{"$des_phd","phd"}){
        print 
            "*** ERROR wrtRes1: for protname=$protname, ",
            "des_phd=$des_phd, no file=",$fileTmp{"$des_phd","phd"},"!!\n";}
    else {
        @rd=&wrtRes1merde1($fileTmp{"$des_phd","phd"},$des_key);
        &wrtRes1merde2($fhoutLoc,$des_phd,$des_key,@rd); 
        print $fhoutLoc "*"," " x 74,"*\n"; }
				# ------------------------------
				# get pay_offs
    if ( $USERID ne "phd" && $par{"optDoEval"}) {
        $des_key="footer";
        $#rdEval=0;
        foreach $des_phd(@optPhd_loc){
            push(@rdEval,&wrtRes1merde1($fileTmp{"$des_phd","phd"},$des_key));}}
				# ------------------------------
				# convert RDB files
    %tmp=
        &rdbphd_to_dotpred($par{"verb2"},$par{"nresPerRow"},
                           $par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSec"},
                           $optPhd_loc,$filePhdTmp,$protname,
                           $par{"optDoHtmref"},$par{"optDoHtmtop"},@file);
    push(@protname,$protname);
    undef %tmp;                 # sbr writes file (filePhdTmp) -> see next lines 
				# ------------------------------
				# write results
    $Lok=&open_file("$fhin","$filePhdTmp");
    if ($Lok){
	while(<$fhin>){
	    print $fhoutLoc $_;}close($fhin);}
				# ------------------------------
				# write pay_offs
    if ( $USERID ne "phd" && $par{"optDoEval"}) {
        &wrtRes1merde2($fhoutLoc,$des_phd,$des_key,@rdEval);
        $#rdEval=0;}
    close($fhoutLoc);

    push(@fileOutPhdOk,$filePhd) if (-e $filePhd);
    push(@fileOutRdbOk,$fileRdb) if (-e $fileRdb);
    return(1,"ok $sbrName");
}				# end of wrtRes1

#===============================================================================
sub wrtRes1merde1 {
    local ($fileIn,$key_in) = @_ ;
    local ($fhin,$tmp,@rd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtRes1merde1              filters the shit part 1 in the fortran output
#--------------------------------------------------------------------------------
    $fhin="FHIN_WRTRES1_GETHF";
    &open_file("$fhin","$fileIn") || return();
    $Lok=$#rd=0;
    while(<$fhin>){
        $rd=$_;                 # 
        last if ( $rd !~ /^\*/) ;
        if ($key_in !~/^protein|^footer/) {
            next if (! $Lok && $rd !~ /$key_in/);
            if (! $Lok && $rd=~/$key_in/) {
                $Lok=1;
                next; }
            if ($rd=~/^\*\*\*\*/) {
                $Lok=0;
                next;}          # 
            $tmp=$rd;$tmp=~s/\n|~//g;$tmp=~s/^\*[\s-]*|[\s-]\*$//g;
            push(@rd,$tmp)      if (length($tmp)>1);
            next; }
        if ($key_in=~/^protein/) {
            next if ( $rd !~/^\*.*protein:.+len/ );
            if ($rd=~/^\*\*\*\*/) {
                $Lok=0;
                next;}
            $tmp=$rd;$tmp=~s/\n|~//g;$tmp=~s/^\*[\s-]*|[\s-]\*$//g;
            push(@rd,$tmp)      if (length($tmp)>1); }}

                                # continue reading
    if ($key_in=~/footer/){
	while(<$fhin>){
            $rd=$_;
            next if($rd !~/^\s*[|+]/);
            $tmp=$rd;
	    $tmp=~s/\n//g;
	    $tmp=~s/^[* ]\s*|\s*[ *]$//;
	    $tmp=~s/\0/ /g;
	    $tmp=~s/\s+$//g;
            push(@rd,$tmp); 
	}
    }
    close($fhin);
    return (@rd);
}				# end of wrtRes1merde1

#===============================================================================
sub wrtRes1merde2 {
    local ($fh,$des_phd,$des,@rd) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtRes1merde2              filters the shit part 2 in the fortran output
#--------------------------------------------------------------------------------
    if    ($des=~/Abbrev/)  {$tmp=$des." PHD"."$des_phd";
			     return; }
    elsif ($des=~/^footer/) {print $fh "*"," " x 74,"*\n","*","*" x 74,"*\n","*"," " x 74,"*\n"; 
			     $tmp="Prediction accuracy for"." PHD"."$des_phd";}
    elsif ($des=~/^protein/){print $fh "*"," " x 74,"*\n"; 
			     $tmp=""; }
    else {$tmp=$des;}
    if (length($tmp)>0){
	printf $fh "*    %-30s %-38s *\n",$tmp," ";
	printf $fh "*    %-30s %-38s *\n","~"x length($tmp)," ";
	print  $fh "*"," " x 74,"*\n";
    }
    foreach $rd (@rd) {
	next if ( ($des=~/WARNING/)&&($rd=~/^========/) );               # hack 1
	next if ( ($des=~/Some statis/)&&($rd eq "+--------------+") );  # hack 2
	print  $fh "*"," " x 74,"*\n" 
            if ( ($des=~/Some statis/)&&($rd=~/^Percen.+sec|^Percen.+heli/) );
        print  $fh "*"," " x 74,"*\n"
            if ( ($des=~/Some statis/)&&($rd=~/^Accord/) );
	    
	if ( ($des=~/Some statis/)&&($rd=~/^all-alpha|alpha-beta/) ) {
	    printf $fh "*       %-66s *\n",substr($rd,1,66); }
	elsif ($des=~/Abbrev/){
	    if    ($rd=~/^AA|^SS/)     { 
		$rd=~s/^(..)/   $1 /;}
	    elsif ($rd=~/^i\.e|output|^an ex|^L\:|^\"\.|^as the|note/)   { 
		$rd=~s/^(.)/        $1/;}
	    elsif ($rd=~/^b =|^\"I|^\"\.|^= n/)   { 
		$rd=~s/^(.)/        $1/;}
	    elsif ($rd=~/^Note/)   { 
		$rd=~s/^Note:\s+/        note: /;}
	    elsif ($rd =~/^Subset/) {
		printf $fh "*    %-69s *\n","subset:"; 
		$rd=~s/Subset:\s+/   /;}
	    elsif ($rd !~/^secondary|^detail|^subset/) {
		$rd=~s/10st: /10st:/ if ($rd =~/^10st/);
		$rd=~s/^(.)/   $1/;}
	    printf $fh "*    %-69s *\n",substr($rd,1,69); }
	elsif ($des=~/footer/){
	    printf $fh " %-s\n",$rd; }
	else {
	    printf $fh "*    %-69s *\n",substr($rd,1,69); }
    }
}				# end of wrtRes1merde2

#===============================================================================
sub wrtRes1other {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRes1other                PHD -> MSF|SAF, DSSP, HTML
#      GLOBAL                   all
#-------------------------------------------------------------------------------
    $sbrName="lib-phd:wrtRes1other";

				# ------------------------------
				# PHD + HSSP -> MSF/SAF
				# ------------------------------
    if ($par{"doRetAli"}) {
	($Lok,$msg)=
	    &phdAliWrt($fileHssp,$chainHssp,$file{"fileOutRdb"},
		       $par{"fileOutAli"},$par{"formatRetAli"},
		       $par{"doRetAliExpand"},$par{"riSubSec"},$par{"riSubAcc"},
		       $par{"riSubSym"},$par{"nresPerRowAli"});
	return(&errSbrMsg("failed writing file PHD+ali",$msg)) if (! $Lok); 
	return(&errSbr("no output fileAli=".$par{"fileOutAli"},$msg)) 
	    if (! -e $par{"fileOutAli"}); }

				# ------------------------------
				# convert PHD.rdb to DSSP
				# ------------------------------
    if ($par{"doRetDssp"}) {
	$cmd=$cmdSys="";
	$cmd=$par{"exePhd2dssp"}." ".$file{"fileOutRdb"}." fileOut=".$par{"fileOutDssp"};
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=     
	    &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("phd2dssp ($cmd)",$msg)) if (! $Lok);
	return(&errSbr("no output fileDssp=".$par{"fileOutDssp"},$msg)) 
	    if (! -e $par{"fileOutDssp"}); }

				# ------------------------------
				# convert PHD.rdb to HTML
				# ------------------------------
    if ($par{"doRetHtml"}) {
	$cmd=$cmdSys="";
	$cmd=$par{"exePhd2html"}." ".$file{"fileOutRdb"}." fileOut=".$par{"fileOutHtml"};
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=     
	    &sysRunProg($cmdSys,$par{"fileOutScreen"},$fhTrace);
	return(&errSbrMsg("phd2html ($cmd)",$msg)) if (! $Lok);
	return(&errSbr("no output fileHtml=".$par{"fileOutHtml"},$msg)) 
	    if (! -e $par{"fileOutHtml"}); }

    return(1,"ok $sbrName");
}				# end of wrtRes1other

#===============================================================================
sub wrtScreenHeader {
#-------------------------------------------------------------------------------
#   wrtScreenHeader             write header onto screen
#-------------------------------------------------------------------------------
    local ($tmp);
    $[ =1 ;
    $tmp =  $par{"exePhd"}; $tmp2=$tmp;$tmp2=~s/(ALPHA|SGI\d*|SUNMP|SUN4)//g;

    print $fhTrace2 
	"---     ------------------------------------------------- \n",
	"---     Dear User, \n","---      \n",
	"---     Welcome to PHD the three level neural network  \n",
	"---     prediction of: \n",
	"---                   secondary structure in 3 states, \n",
	"---                   solvent accessibility in 10 states, \n",
	"---                   or helical trans-membrane regions in 2 states. \n",
	"---      \n",
	"---     either call with:  \n",
	"---     	'$tmp file.HSSP'  \n",
	"---     or use defaults :  \n",
	"---     	'$tmp' \n",
	"---     in which case you will be requested to name a \n",
	"---     file containing an alignment in the format of \n",
	"---     HSSP \n","---      \n",
	"---     Further options, call with: \n",
	"---     	'$tmp option1 option2 option3 option4 option5' \n",
	"---     where: \n",
	"---          option1 = 'machine' -> output strings machine readable \n",
	"---          option2 = 'whatif'  -> additional output file giving prediction \n",
	"---          option3 = 'pdb_id'  -> the prediction is based on a training without pdb_id\n",
	"---          option4 = 'rdb'     -> additional output file in RDB format \n",
	"---                                 the produced table *.rdb* can be read by GENEQUIZ \n",
	"---          option5 = 'sec'     -> PHD predicts secondary structure \n",
	"---                  = 'exp'     -> PHD predicts exposure \n",
	"---                  = 'both'    -> PHD predicts secondary structure and exposure \n",
	"---                  = 'htm'     -> PHD predicts helical trans-membrane regions \n",
	"---     Note: the succession of the options is arbitrary. \n",
	"---      \n",
	"---     in case of difficulties, feel free to contact: \n",
	"---        	Burkhard Rost \n",
	"---        	internet: Rost\@EMBL-Heidelberg.DE \n",
	"---      \n",
	"---     One common trouble is: that your environment \n",
	"---     does not define a ARCH, i.e. the machine type. \n",
	"---     If so, please use:  \n",
	"---     	'$tmp2", ".ARCH \n",
	"---     where MACHINE is  \n",
	"---     	= ALPHA, for nu \n",
	"---     	= SGI5,  for hawk, falcon, asf \n",
	"---     	= SGI64, for phenix \n",
	"---     	= SUN4,  for zinc, copper, chrome, asf \n",
	"---      \n",
	"---     ------------------------------------------------- \n",
	"---      \n";
}				# end of wrtScreenHeader

#===============================================================================
sub wrtScreenFin {
    local ($headPhd_tmp,$filePhd) = @_;
#-------------------------------------------------------------------------------
#   wrtScreenFin                write final words onto screen
#-------------------------------------------------------------------------------

    $timeEnd=time;
    $timeRun=$timeEnd-$timeBeg;
    print $fhTrace2 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
    if ($USERID !~ /rost/){
	print $fhTrace2 
	    "--- \n",
	    "--- ", "-" x 74 , " ---\n",
	    "--- \n";

	print $fhTrace2 "--- date $Date, run time ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
	print $fhTrace2 
	    "---     The program PredictProtein has ended successfully !\n",
	    "---     Thanks for Your interest !\n","--- \n",
	    "---     .......................................\n",
	    "---     Copyright:      Burkhard Rost          \n",
	    "---                     rost\@LION-AG.DE\n",
	    "---     .......................................\n","--- \n",
	    "---     Some information about the PHD method is given in the file \n",
	    "---        $headPhd_tmp \n",
	    "---        ","=" x length($headPhd_tmp), " \n","--- \n";}

    print $fhTrace2 "---     Output files:\n";
    undef %ok;

    foreach $des (@desFileOut,@desFileOutList,@desFileOutCtrl){
	if (defined $par{$des} && -e $par{$des}){
	    printf $fhTrace2 "--- %-20s %-s\n",$des,$par{$des};
	    $ok{$par{$des}}=1;}}

    foreach $itfile (1..$#fileOutPhdOk) {
	$fileOutPhdOk[$itfile]=0 
	    if (! defined $fileOutPhdOk[$itfile] || ! -e $fileOutPhdOk[$itfile]);
	$fileOutRdbOk[$itfile]=0
	    if (! defined $fileOutRdbOk[$itfile] || ! -e $fileOutRdbOk[$itfile]);
	next if (! $fileOutPhdOk[$itfile] && ! $fileOutRdbOk[$itfile]);
	printf $fhTrace2 "--- %-15s %4d :","out phd",$itfile;
	printf $fhTrace2 " %-20s ",$fileOutPhdOk[$itfile]  if ($fileOutPhdOk[$itfile]);
	printf $fhTrace2 " %-20s ",$fileOutRdbOk[$itfile]  if ($fileOutRdbOk[$itfile]); 
	print  $fhTrace2 "\n"; }

    if ($USERID !~/rost|phd/){
	print $fhTrace2 
	    "---     Have more or less fun with evaluating the results. \n",
	    "---     -------------------------------------------------- \n";}
}				# end of wrtScreenFin 

1;
