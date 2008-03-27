package agape;

sub run_agape{
    my $sbr="run_agape";
    ($configFile,$FastaIn,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$dbg)=@_;
    return(0,"ERROR $sbr: arguments not defined, stopped")
	if(! defined $configFile    || ! defined $FastaIn || 
	   ! defined $finalMpearson || ! defined $finalAL || 
	   ! defined $finalMpdb);
   
   
    if(! defined $dbg){ $dbg=0; }


    #require $configFile == 1 || 
#	return(0,"ERROR $sbr: failed to require config file: $configFile, stopped");#

#    print "parameters:\n";
#    foreach $key (sort keys %main::par){ print "par key: $key\n"; }
    
    $pathLoc=`pwd`;   #to do: replace it with perl;
    $pathLoc=~s/\s//g; 
    $pathLoc.="/" if($pathLoc !~ /\/$/);
    
    $work_dir_loc=$pathLoc;
   
    $QueryName    ="query";
    $FastaInLoc   ="query.f";
    
    open(FHFASTALOC,">".$FastaInLoc);
    open(FHFASTAIN,$FastaIn) || 
	return(0,"failed to open FastaIn=$FastaIn, stopped");
    while(<FHFASTAIN>){
	if(/^>/){
	    ($queryInfo)=/^>\S+\s*(.*)\s*$/;
	    print FHFASTALOC ">query  $queryInfo\n";
	}
	else{print FHFASTALOC $_; }
    }
    close FHFASTAIN; close FHFASTALOC;


    $QueryID="query";


    if($dbg){ $LogFile  =$QueryID."_agepe.log"; }
    else{     $LogFile  =$main::par{'log_dir'}.$QueryID."_agape.log"; 
	      $ErrFile  =$main::par{'log_dir'}.$QueryID."_agape.err";
    }

    if(! $dbg){ open(STDERR,">".$ErrFile); 
		open(STDOUT,">".$LogFile); }

    print "INFO: FastaIn=$FastaIn\n";

    #get number of proteins in the maxhom database files
    return(0,"maxhom dssp database $par{db_dssp_list} not found, stopped")
	if(! -e $main::par{'db_dssp_list'});
    return(0,"maxhom sssa database $par{db_sssa_list} not found, stopped")
	if(! -e $main::par{'db_sssa_list'});

    $BlastForProfOut      =$work_dir_loc.$QueryID.".BlastForProf";

    $BlastMatOut          =$work_dir_loc.$QueryID.".BlastMat";
    $BlastForProfileTmp   =$work_dir_loc.$QueryID.".Blastpgp_tmp";
    
    $FileSaf              =$work_dir_loc.$QueryID.".saf";
    $FileSafHssp          =$work_dir_loc.$QueryID.".hsspFromSaf";
    $FileSafHsspFilt      =$work_dir_loc.$QueryID.".hsspFromSafFilt";
    #$FileHsspForProf      =$work_dir_loc.$QueryID.".hssp";

    $FileProfRdb          =$work_dir_loc.$QueryID.".rdbProf";
    $FileQueryDssp        =$work_dir_loc.$QueryID.".dssp";
    $FileSeqSecAcc        =$work_dir_loc.$QueryID.".SeqSecAcc";
    $FileSssaProfile      =$work_dir_loc.$QueryID.".sssa_profile";

    $FileMaxhomFrwdHssp   =$work_dir_loc.$QueryID.".hssp-frwd";
    $FileMaxhomFrwdStrip  =$work_dir_loc.$QueryID.".strip-frwd";
    $FileMaxhomRvsdHssp   =$work_dir_loc.$QueryID.".hssp-rvsd";
    $FileMaxhomRvsdStrip  =$work_dir_loc.$QueryID.".strip-rvsd";
    $FileMaxhom2passList  =$work_dir_loc.$QueryID.".2pass.list"; 

    $FileParsedFrwdStrip  =$work_dir_loc.$QueryID.".frwd-parsed";
    $FileParsedRvsdStrip  =$work_dir_loc.$QueryID.".rvsd-parsed"; 

    $FileParsedCombined   =$work_dir_loc.$QueryID.".comb-parsed";
    $FileFrwdAliIds       =$work_dir_loc.$QueryID.".frwd-aliIds";
    $FileRvsdAliIds       =$work_dir_loc.$QueryID.".rvsd-aliIds";

    #$FileParsedFrwdStripEvd  =$work_dir_loc.$QueryID.".frwd-parsed_evd";
    #$FileParsedRvsdStripEvd  =$work_dir_loc.$QueryID.".rvsd-parsed_evd"; 

    #$FileParsedFrwdStripEvdC  =$work_dir_loc.$QueryID.".frwd-parsed_evd_c";
    #$FileParsedRvsdStripEvdC  =$work_dir_loc.$QueryID.".rvsd-parsed_evd_c"; 

    $FileFrwdMpearson     =$work_dir_loc.$QueryID.".frwd-mpearson";
    $FileRvsdMpearson     =$work_dir_loc.$QueryID.".rvsd-mpearson";
    $FileMpearson         =$work_dir_loc.$QueryID.".mpearson";
    $FileShort            =$work_dir_loc.$QueryID.".short";

    if(! defined $FileOutAL){ $FileOutAL=$work_dir_loc.$QueryID.".AL"; }
    if(! defined $FileOutMpdb){ $FileOutMpdb=$work_dir_loc.$QueryID.".TS"; }
    
    
    $BlastForProfCmd="$main::par{blastpgp_exe} -i $FastaInLoc -d $main::par{traindb} -j 2 -o $BlastForProfOut -e 1 -h 0.1 -v 5000 -b 5000 -a 2";
    print "executing:\n$BlastForProfCmd\n"  if($dbg);
    $Lok=system($BlastForProfCmd);
    return(0,"ERROR $sbr: command=$BlastForProfCmd failed, stopped")
	   if( ($Lok != 0) || (! -e $BlastForProfOut) );
	   
    $BlastToSafCmd="$main::par{blast2saf_exe} $BlastForProfOut fasta=$FastaInLoc eSaf=1 maxAli=5000 saf=$FileSaf";
    print "executing:\n$BlastToSafCmd\n"  if($dbg);
    $Lok=system($BlastToSafCmd);
    
    return(0,"ERROR $sbr: command=$BlastToSafCmd failed, stopped")
	if($Lok != 0);


    $SafToHsspCmd="$main::par{copf_exe} $FileSaf fileOut=$FileSafHssp hssp";
    print "executing:\n$SafToHsspCmd\n"  if($dbg);
    $Lok=system($SafToHsspCmd);
    return(0,"ERROR $sbr: command=$SafToHsspCmd failed, stopped")
	if($Lok != 0);

    $HsspFilterCmd="$main::par{hssp_filter_exe} $FileSafHssp fileOut=$FileSafHsspFilt red=80";
    $tmp=`pwd`;
    print $tmp."\n";
    print "executing:\n$HsspFilterCmd\n"  if($dbg);
    $Lok=system($HsspFilterCmd);
    return(0,"ERROR $sbr: command=$HsspFilterCmd failed, stopped")
	if($Lok != 0);



    $ProfCmd="$main::par{prof_exe} $FileSafHsspFilt fileOut=$FileProfRdb";
    print "executing:\n$ProfCmd\n"  if($dbg);
    $Lok=system($ProfCmd);
    return(0,"ERROR $sbr: command=$ProfCmd failed, stopped")
	if($Lok != 0);


    $BlastForProfileCmd="$main::par{blastpgp_exe} -i $FastaInLoc -d $main::par{traindb} -j 5 -o $BlastForProfileTmp -Q $BlastMatOut -e 0.1 -h 0.1 -v 5000 -b 5000 -a 2";
    print "executing:\n$BlastForProfileCmd\n"  if($dbg);
    $Lok=system($BlastForProfileCmd);
    return(0,"ERROR $sbr: command=$BlastForProfileCmd failed, stopped")
	if( ($Lok != 0) || (! -e $BlastForProfileTmp) );


    $conv_phd2dsspCmd="$main::par{conv_phd2dssp_exe} $FileProfRdb fileOut=$FileQueryDssp";
    print "executing:\n$conv_phd2dsspCmd\n"  if($dbg);
    $Lok=system($conv_phd2dsspCmd);
    return(0,"ERROR $sbr: command=$conv_phd2dsspCmd failed, stopped")
	if($Lok != 0);



    $DsspExtrSeqSecAccCmd="$main::par{dsspExtrSeqSecAcc_exe} $FileQueryDssp fileOut=$FileSeqSecAcc";
    print "executing:\n$DsspExtrSeqSecAccCmd\n"  if($dbg);
    $Lok=system($DsspExtrSeqSecAccCmd);
    return(0,"ERROR $sbr: command=$DsspExtrSeqSecAccCmd failed, stopped")
	if($Lok != 0);



    $mat2maxsssaprofCmd="$main::par{mat2maxsssaprof_exe} $BlastMatOut rdbphd=$FileProfRdb strmat=$main::par{strmat}";
    print "executing:\n$mat2maxsssaprofCmd\n"  if($dbg);
    $Lok=system($mat2maxsssaprofCmd);
    return(0,"ERROR $sbr: command=$mat2maxsssaprofCmd failed, stopped")
	if($Lok != 0);



    $Maxhom_frwdCmd="$main::par{maxhom_frwd_exe} $FileSssaProfile $main::par{db_dssp_list} $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_frwdCmd\n"  if($dbg);
    $Lok=system($Maxhom_frwdCmd);
    return(0,"ERROR $sbr: command=$Maxhom_frwdCmd failed, stopped")
	if($Lok != 0);

    $Maxhom_rvsdCmd="$main::par{maxhom_rvsd_exe} $FileQueryDssp $main::par{db_sssa_list} $FileMaxhomRvsdHssp $FileMaxhomRvsdStrip $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_rvsdCmd\n"  if($dbg);
    $Lok=system($Maxhom_rvsdCmd);
    return(0,"ERROR $sbr: command=$Maxhom_rvsdCmd failed, stopped")
	if($Lok != 0);


    $main::parseStripFrwdCmd="$main::par{parseStripFrwd_exe} $FileMaxhomFrwdStrip $main::par{db_relat} $main::par{db_dssp_list}";
    print "executing:\n$main::parseStripFrwdCmd\n"  if($dbg);
    $Lok=system($main::parseStripFrwdCmd);
    return(0,"ERROR $sbr: command=$main::parseStripFrwdCmd failed, stopped")
	if($Lok != 0);

    $main::parseStripRvsdCmd="$main::par{parseStripRvsd_exe} $FileMaxhomRvsdStrip $main::par{db_stat} $main::par{db_sssa_list}";
    print "executing:\n$main::parseStripRvsdCmd\n"  if($dbg);
    $Lok=system($main::parseStripRvsdCmd);
    return(0,"ERROR $sbr: command=$main::parseStripRvsdCmd failed, stopped")
	if($Lok != 0);

    $frwdRvsdScoreCmd="$main::par{frwdRvsdScore_exe} $FileParsedFrwdStrip $FileParsedRvsdStrip $FileParsedCombined";
    print "executing:\n$frwdRvsdScoreCmd\n"  if($dbg);
    $Lok=system($frwdRvsdScoreCmd);
    return(0,"ERROR $sbr: command=$frwdRvsdScoreCmd failed, stopped")
	if($Lok != 0);


    undef $queryTmp; undef %h_homID2scores;
    return(0,"ERROR $sbr: para max_ali_rank not defined, stopped")
	if(! defined $main::par{'max_ali_rank'});
    open(FHINLOC,$FileParsedCombined) || 
	return(0,"ERROR $sbr: failed to open FileParsedCombined=$FileParsedCombined, stopped");
    open(FHOUTFRWDLOC,">".$FileFrwdAliIds) || 
	return(0,"ERROR $sbr: failed to open FileFrwdAliIds=$FileFrwdAliIds for output, stopped");
    open(FHOUTRVSDLOC,">".$FileRvsdAliIds) || 
	return(0,"ERROR $sbr: failed to open FileRvsdAliIds=$FileRvsdAliIds for output, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^\#/);
	s/\s*$//;
	($queryTmp,$rank,$HomID,$Pval,$better,$Eval)=split(/\t/,$_);
	return(0,"ERROR $sbr: ranking data not defined in line=$_\n, stopped")
	    if(! defined $better);
	return(0,"ERROR $sbr: rank for HomID=$HomID already defined, stopped")
	    if(defined $h_homID2scores{$HomID}{'rank'});
	$h_homID2rank{$HomID}{'rank'}=$rank;
	$h_homID2rank{$HomID}{'pval'}=$Pval;
	$h_homID2rank{$HomID}{'eval'}=$Eval;
	if($better eq "frwd"){ print FHOUTFRWDLOC $HomID."\n"; }
	elsif($better eq "rvsd"){ print FHOUTRVSDLOC $HomID."\n"; }
	else{ return(0,"ERROR $sbr: indicator=$better is not frwd or rvsd, stopped"); }

	last if($rank >= $main::par{'max_ali_rank'});
    }
    close FHOUTFRWDLOC; close FHOUTRVSDLOC;

    $hsspFrwd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomFrwdHssp $FastaInLoc $main::par{db_mfasta} $FileFrwdAliIds $FileFrwdMpearson";
    print "executing:\n$hsspFrwd2mpearsonCmd\n"  if($dbg);
    $Lok=system($hsspFrwd2mpearsonCmd);
    return(0,"ERROR $sbr: command=$hsspFrwd2mpearsonCmd failed, stopped")
	if($Lok != 0);

    $hsspRvsd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomRvsdHssp $FastaInLoc $main::par{db_mfasta} $FileRvsdAliIds $FileRvsdMpearson";
    print "executing:\n$hsspRvsd2mpearsonCmd\n"  if($dbg);
    $Lok=system($hsspRvsd2mpearsonCmd);
    return(0,"ERROR $sbr: command=$hsspRvsd2mpearsonCmd failed, stopped")
	if($Lok != 0);

    #$hssp_to_AL_exeCmd="$main::par{hssp_to_AL_exe} $FastaInLoc $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $FileOutAL $QueryID $dbg";
    #print "executing:\n$hssp_to_AL_exeCmd\n"  if($dbg);
    #$Lok=system($hssp_to_AL_exeCmd);
    #return (0,"ERROR $sbr: command=$hssp_to_AL_exeCmd failed, stopped")
    #    if($Lok != 0);

    #combine and order mpearson files
    undef %h_mpearson;
    ($Lok,$msg)=&read_mpearson($FileFrwdMpearson,\%h_mpearson);
    return(0,"ERROR $sbr: $msg") if(! $Lok);
 
    ($Lok,$msg)=&read_mpearson($FileRvsdMpearson,\%h_mpearson);
    return(0,"ERROR $sbr: $msg") if(! $Lok);
    
    open(FHOUTMP,">".$FileMpearson) ||
	return(0,"ERROR $sbr: failed to open FileMpearson=$FileMpearson for output, stopped");
    foreach $HomID (sort {$h_homID2rank{$a}{'rank'} <=> $h_homID2rank{$b}{'rank'}} 
		    keys %h_homID2rank ){
	return(0,"ERROR $sbr: pearson for HomID=$HomID not defined, stopped")
	    if(! defined $h_mpearson{$HomID});
	$Pval=$h_homID2rank{$HomID}{'pval'}; 
	$Pval=sprintf "%1.3e", $Pval; $Pval=~s/\s//g;
	$Eval=$h_homID2rank{$HomID}{'eval'};
	$Eval=sprintf "%1.3e", $Eval; $Eval=~s/\s//g;
	print FHOUTMP ">".$HomID."\t"."P-value=".$Pval."\t"."E-value=".$Eval."\n";
	print FHOUTMP "query\t".$h_mpearson{$HomID}{"query"}."\n";
	print FHOUTMP "$HomID\t".$h_mpearson{$HomID}{"subject"}."\n";
    }
    close FHOUTMP;

    $mpearson2ALmpdbCmd="$main::par{mpearson2ALmpdb_exe} $FileMpearson $FileOutMpdb $FileOutAL";
    print "executing:\n$mpearson2ALmpdbCmd\n"  if($dbg);
    $Lok=system($mpearson2ALmpdbCmd);
    return(0,"ERROR $sbr: command=$mpearson2ALmpdbCmd failed, stopped")
	if($Lok != 0);

    $mpearson2shortCmd="$main::par{mpearson2short_exe} $FileMpearson $FileShort";
    print "executing:\n$mpearson2shortCmd\n"  if($dbg);
    $Lok=system($mpearson2shortCmd);
    return(0,"ERROR $sbr: command=$mpearson2shortCmd failed, stopped")
	if($Lok != 0);

    
    $cmd="\\cp -p $FileMpearson $finalMpearson";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutAL $finalAL";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutMpdb $finalMpdb";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileShort $finalShort";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");
    
    $cmd="\\cp -p $finalMpdb $finalAL $finalMpearson $main::par{results_dir}";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

 
    
    if(! $dbg){
	unlink ($BlastForProfileTmp,$BlastForProfOut,$BlastMatOut,$FileSaf,$FileSafHssp,$FileSafHsspFilt,$FileProfRdb,$FileQueryDssp,$FileMaxhomFrwdHssp,$FileMaxhomFrwdStrip,$FileMaxhomRvsdHssp,$FileMaxhomRvsdStrip,$FileSeqSecAcc,$FileSssaProfile,"collage-stat.data");
    }

    if(! $dbg && defined $ErrFile && -e $ErrFile){
	unlink $ErrFile;
    }
#    if(! $dbg){ system("\\rm -rf $work_dir_loc"); }
#    print "Output in $FileOutAL\n";
#    print "threader done :) \n";

    #$Cmd="";
    #$Lok=system();
    #return(0,"ERROR: command= failed, stopped")
    #    if($Lok != 0);

    return(1,"ok");
}
#===========================================================================    
#============================================================================
sub read_mpearson{
    my $sbr="read_mpearson";
    my ($file,$hr_mpearson)=@_;
    return(0,"ERROR $sbr: arguments not defined, stopped")
	if(! defined $file || ! defined $hr_mpearson);
    my ($HomID,$ctLoc,$aliStrin,$id);
    open(FHINMP,$file) || 
	return(0,"ERROR $sbr: failed to open file=$file, stopped");
    while(<FHINMP>){
	next if(/^\s*$|^\#/);
	if(/^>(\S+)/){ $HomID=$1; $ctLoc=0; undef $aliString; undef $id;}
	elsif(/^(\S+)\t(\S+)/){ 
	    $id=$1; $aliString=$2; $ctLoc++;
	    if($ctLoc==1){ $$hr_mpearson{$HomID}{'query'}=$aliString; }
	    elsif($ctLoc==2){ 
	    return(0,"ERROR $sbr: format of $file not understood, stopped")
		if($id ne $HomID);
	    $$hr_mpearson{$HomID}{'subject'}=$aliString; 
	}
	    else{ return(0,"ERROR $sbr: format of $file not understood, stopped"); }
	}
    }
    close FHINMP;
    return (1,"ok");
}
#=============================================================================
#=========================================================================
sub check_fasta{
    local $sbr='get_data_from_fasta';
    my $FastaFile=$_[0];
    my $fhLOC='FHLOC';
    my ($ct,$ctw,$FailFlag,$formfile,$formSeq,$NucleicFlag,
	$sequence,$length,$Id,$idTmp,$chain,@tmp);
    return(0,&error("argument FastaFile not defined",__FILE__,__LINE__) ) 
	if (! defined $FastaFile);
    open($fhLOC,$FastaFile) ||
	return(0,&error("did not open file=$FastaFile",__FILE__,__LINE__) );
    while (<$fhLOC>){
	next if ($_ =~ /^\s*$|^\#/ );
	if($_ =~ /^>(\S+)/){
	    $Id=$1;
	    if($Id=~/^>pdb\|(\d.*)\|(\S*)/){
		$idTmp=$1; $chain=$2; $idTmp=~tr[A-Z][a-z];
		$Id=$idTmp.$chain;
	    }else{
		$Id=~s/.*\|//;
	    }
	    $Id =PDB_id_format($Id);
	    next;
	} 
	$_=~s/\s//g;
	$_=~s/\!//g;
	$sequence.=$_;
    }
    close $fhLOC;
    $length=length($sequence);
    if($sequence !~ /[^ACGUTIXF]/i){ $NucleicFlag=1; }
    else{ $NucleicFlag=0; }
    @tmp=split(//,$sequence);
    $ct=0; $ctw=0;
    $formSeq="";
    foreach $i (0 .. $#tmp){
	$ct++; $ctw++;
	$formSeq.=$tmp[$i];
	if($ctw%50 == 0){ $formSeq.="\n"; }
	elsif($ct%10 ==0){$formSeq.=" "; }
    }
    if($formSeq !~ /\n$/){ $formSeq.="\n"; }
    $formfile=">".$Id."\n".$formSeq;
    #print "here:\n";
    #print "$Id,$length,$sequence,$formSeq,$formfile,$NucleicFlag\n";
    return(1,'ok',$Id,$length,$sequence,$formSeq,$formfile,$NucleicFlag);
}

#===============================================================================


1;
