package agape;

sub run_agape{
    my $sbr="run_agape";
    ($configFile,$FastaIn,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$jobID,$dbg)=@_;
    return(0,"ERROR $sbr: arguments not defined, stopped")
	if(! defined $configFile    || ! defined $FastaIn || 
	   ! defined $finalMpearson || ! defined $finalAL || 
	   ! defined $finalMpdb || ! defined $jobID);
   
   
    if(! defined $dbg){ $dbg=0; }
    
    print "debug on !!!\n" if($dbg);
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
	print $_;
	if(/^>/){
	    ($QueryNameTmp,$QueryInfo)=/^>(\S+)\s*(.*)\s*$/;
	    if(/\(\#\)\s*(\S+)/){
		$QueryNameTmp=$1;
	    }
	    print FHFASTALOC ">query  $QueryInfo\n";
	    ($QueryTitle)=/description=(\S+)/;
	}
	else{print FHFASTALOC $_; }
    }
    close FHFASTAIN; close FHFASTALOC;
    
    if(! defined $QueryTitle){ $QueryTitle=$QueryNameTmp;}

    print "INFO: queryTitle=$QueryTitle\n";
    $QueryID="query";

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

    $FileMaxhomFrwdHsspBest   =$work_dir_loc.$QueryID.".hssp-frwd-best";
    $FileMaxhomFrwdStripBest  =$work_dir_loc.$QueryID.".strip-frwd-best";
    $FileMaxhomRvsdHsspBest   =$work_dir_loc.$QueryID.".hssp-rvsd-best";
    $FileMaxhomRvsdStripBest  =$work_dir_loc.$QueryID.".strip-rvsd-best";


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

    print "dbg=$dbg after maxhom_rvsd\n";

    $parseStripFrwdCmd="$main::par{parseStripFrwd_exe} $FileMaxhomFrwdStrip $main::par{db_relat} $main::par{db_dssp_list}";
    print "executing:\n$parseStripFrwdCmd\n"  if($dbg);
    $Lok=system($parseStripFrwdCmd);
    return(0,"ERROR $sbr: command=$parseStripFrwdCmd failed, stopped")
	if($Lok != 0);

    $parseStripRvsdCmd="$main::par{parseStripRvsd_exe} $FileMaxhomRvsdStrip $main::par{db_stat} $main::par{db_sssa_list}";
    print "executing:\n$parseStripRvsdCmd\n"  if($dbg);
    $Lok=system($parseStripRvsdCmd);
    return(0,"ERROR $sbr: command=$parseStripRvsdCmd failed, stopped")
	if($Lok != 0);

    $frwdRvsdScoreCmd="$main::par{frwdRvsdScore_exe} $FileParsedFrwdStrip $FileParsedRvsdStrip $FileParsedCombined";
    print "executing:\n$frwdRvsdScoreCmd\n"  if($dbg);
    $Lok=system($frwdRvsdScoreCmd);
    return(0,"ERROR $sbr: command=$frwdRvsdScoreCmd failed, stopped")
	if($Lok != 0);


    undef $queryTmp; undef %h_homID2scores; 
    return(0,"ERROR $sbr: para max_ali_rank not defined, stopped")
	if(! defined $main::par{'max_ali_rank'});
    $maxRankLoc=$main::par{'max_ali_rank'} * 4; #to allow combininig domains from different templates
    open(FHINLOC,$FileParsedCombined) || 
	return(0,"ERROR $sbr: failed to open FileParsedCombined=$FileParsedCombined, stopped");
    open(FHOUTFRWDLOC,">".$FileFrwdAliIds) || 
	return(0,"ERROR $sbr: failed to open FileFrwdAliIds=$FileFrwdAliIds for output, stopped");
    open(FHOUTRVSDLOC,">".$FileRvsdAliIds) || 
	return(0,"ERROR $sbr: failed to open FileRvsdAliIds=$FileRvsdAliIds for output, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^\#/);
	next if(/^queryID/);
	s/\s*$//;
	($queryTmp,$rank,$HomID,$Pval,$better,$Eval,$score,$miu,$lambda)=split(/\t/,$_);
	return(0,"ERROR $sbr: data not defined in $FileParsedCombined: queryTmp=$queryTmp, rank=$rank, HomID=$HomID, Pval=$Pval, better=$better, Eval=$Eval, score=$score, miu=$miu, lambda=$lambda")
	    if(! defined $queryTmp || ! defined $rank || ! defined $HomID || ! defined $Pval  || ! defined $better || ! defined $Eval || ! defined $score || ! defined $miu || ! defined $lambda);
	return(0,"ERROR $sbr: ranking data not defined in line=$_\n, stopped")
	    if(! defined $better);
	return(0,"ERROR $sbr: rank for HomID=$HomID already defined, stopped")
	    if(defined $h_homID2scores{$HomID}{'rank'});
	$h_homID2rank{$HomID}{'rank'}=$rank;
	$h_homID2rank{$HomID}{'pval'}=$Pval;
	$h_homID2rank{$HomID}{'eval'}=$Eval;

	if($better eq "frwd"){
	    $h_homID2rank{$HomID}{'best'}="frwd";
	    print FHOUTFRWDLOC $HomID."\n"; 
	}elsif($better eq "rvsd"){ 
	    $h_homID2rank{$HomID}{'best'}="rvsd";
	    print FHOUTRVSDLOC $HomID."\n"; 
	}else{ return(0,"ERROR $sbr: indicator=$better is not frwd or rvsd, stopped"); }

	last if($rank >= $maxRankLoc);
    }
    close FHOUTFRWDLOC; close FHOUTRVSDLOC;

    #---------------------------------------------------------
    #now find related pdb ids for highest ranks and rerun maxhom on them
    undef %h_allRelatedIdsLoc;
    undef %h_dbIds2pdbHomos; 
    $file_dbIds2pdbHomos=$main::par{'dbIds2pdbHomos'};
    open(FHINLOC,$file_dbIds2pdbHomos) ||
	return(0,"ERROR $sbr: failed to open  file_dbIds2pdbHomos=$file_dbIds2pdbHomos, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^\#/);
	s/\s*$//;
	($id1,$tmp)=split(/\s+/,$_);
	next if(! defined $h_homID2rank{$id1} );
	$h_allRelatedIdsLoc{$id1}=1;
	$h_dbIds2pdbHomos{$id1}{$id1}=1; #make sure self is there
	@l_idsLoc=split(/\,/,$tmp);
	foreach $id2 (@l_idsLoc){ 
	    $h_dbIds2pdbHomos{$id1}{$id2}=1; 
	    $h_allRelatedIdsLoc{$id2}=1;
	}
    }
    close FHINLOC;

    @l_tmp=sort keys %h_allRelatedIdsLoc;
    print "allRelatedIdsLoc: @l_tmp\n" if($dbg);
    
    #check if all needed are there
    foreach $id (sort keys %h_homID2rank){
	return(0,"ERROR $sbr: related ids for $id not defined")
	    if(! defined $h_dbIds2pdbHomos{$id});
    }

    #read resolution (rmsd) of the corresponding pdb files
    open(FHIN,$main::par{'file_pdbRmsd'}) ||
	return(0,"ERROR $sbr: failed to open resolution file=$main::par{file_pdbRmsd}");
    while(<FHIN>){
	next if(/^\s*$|^\#/);
	s/\s*$//;
	($id,$rmsd)=split(/\t/,$_);
	next if( ! defined $h_allRelatedIdsLoc{$id} );
	$h_id2rmsd{$id}=$rmsd;
    }
    close FHIN;

    foreach $id (sort keys %h_allRelatedIdsLoc){
	return(0,"ERROR $sbr: rmsd for $id not defined")
	    if(! defined $h_id2rmsd{$id});
    } #---------------------------------------------------
    


    #now find corresponding dssp and sssa files
    undef %h_dbIds2allpdb_dssp; 
    $file_dbIds2allpdb_dssp=$main::par{'file_dbIds2allpdb_dssp'};
    open(FHINLOC,$file_dbIds2allpdb_dssp) ||
	return(0,"ERROR $sbr: failed to open file_dbIds2allpdb_dssp=$file_dbIds2allpdb_dssp, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^\#/);
	s/\s*$//; 
	($dbId,$dssp)=split(/\s+/,$_);
	next if(! defined $h_allRelatedIdsLoc{$dbId} );
	$h_dbIds2allpdb_dssp{$dbId}=$dssp;
    }
    close FHINLOC;

    foreach $id (sort keys %h_allRelatedIdsLoc){
	return(0,"ERROR $sbr: dssp file for $id not defined")
	    if(! defined $h_dbIds2allpdb_dssp{$id});
    }

    undef %h_dbIds2allpdb_sssa;
    $file_dbIds2allpdb_sssa=$main::par{'file_dbIds2allpdb_sssa'};
    open(FHINLOC,$file_dbIds2allpdb_sssa) ||
	return(0,"ERROR $sbr: failed to open file_dbIds2allpdb_sssa=$file_dbIds2allpdb_sssa, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^\#/);
	s/\s*$//; ($dbId,$sssa)=split(/\s+/,$_);
	next if(! defined $h_allRelatedIdsLoc{$dbId} );
	$h_dbIds2allpdb_sssa{$dbId}=$sssa;
    }
    close FHINLOC;

    foreach $id (sort keys %h_allRelatedIdsLoc){
	return(0,"ERROR $sbr: sssa file for $id not defined")
	    if(! defined $h_dbIds2allpdb_sssa{$id});
    }

    

    $fileDsspListLoc=$QueryID.".best_all_dssp_list";
    open(FHOUT,">".$fileDsspListLoc) ||
	return(0,"failed to open fileOut=$fileDsspListLoc, stopped");
    foreach $id (sort keys %h_dbIds2allpdb_dssp){
	print FHOUT $h_dbIds2allpdb_dssp{$id},"\n";
    }
    close FHOUT;

    $fileSssaListLoc=$QueryID.".best_all_sssa_list";
    open(FHOUT,">".$fileSssaListLoc) ||
	return(0,"failed to open fileOut=$fileSssaListLoc, stopped");
    foreach $id (sort keys %h_dbIds2allpdb_sssa){
	print FHOUT $h_dbIds2allpdb_sssa{$id},"\n";
    }
    close FHOUT;

    
    $Maxhom_frwdCmd2="$main::par{maxhom_frwd_exe} $FileSssaProfile $fileDsspListLoc $FileMaxhomFrwdHsspBest $FileMaxhomFrwdStripBest $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_frwdCmd2\n"  if($dbg);
    $Lok=system($Maxhom_frwdCmd2);
    return(0,"ERROR $sbr: command=$Maxhom_frwdCmd2 failed, stopped")
	if($Lok != 0);

    $Maxhom_rvsdCmd2="$main::par{maxhom_rvsd_exe} $FileQueryDssp $fileSssaListLoc $FileMaxhomRvsdHsspBest $FileMaxhomRvsdStripBest $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_rvsdCmd2\n"  if($dbg);
    $Lok=system($Maxhom_rvsdCmd2);
    return(0,"ERROR $sbr: command=$Maxhom_rvsdCmd2 failed, stopped")
	if($Lok != 0);
    

    #now choose best scoring alignment from ralatives for each dbId
    undef %h_frwdBestScores; $readLoc=0;
    open(FHIN,$FileMaxhomFrwdStripBest) ||
	return(0,"ERROR $sbr: failed to open file=$FileMaxhomFrwdStripBest");
    while(<FHIN>){
	if(/IAL    VAL   LEN IDEL NDEL  ZSCORE/){ $readLoc=1; next; }
	last if(/== ALIGNMENTS ==/);
	next if(! $readLoc);
	$id  =substr($_,70,10); 
	if($id=~/\S\s+\S/){
	    return(0,"ERROR $sbr: wrong format of id=$id in $FileMaxhomFrwdStripBest");
	}
	$val =substr($_,4,8);
	if($val=~/\S\s+\S/){
	    return(0,"ERROR $sbr: wrong format of val=$val in $FileMaxhomFrwdStripBest");
	}

	$id=~s/\s//g; $val=~s/\s//g;
	$h_frwdBestScores{$id}=$val;
    }
    close FHIN;

#    print "h_frwdBestScores:\n";
#    foreach $id (sort keys %h_frwdBestScores){ print "$id\t$h_frwdBestScores{$id}\n"; }

    undef %h_rvsdBestScores; $readLoc=0;
    open(FHIN,$FileMaxhomRvsdStripBest) ||
	return(0,"ERROR $sbr: failed to open file=$FileMaxhomRvsdStripBest");
    while(<FHIN>){
	if(/IAL    VAL   LEN IDEL NDEL  ZSCORE/){ $readLoc=1; next; }
	last if(/== ALIGNMENTS ==/);
	next if(! $readLoc);
	$id  =substr($_,70,10);
	if($id=~/\S\s+\S/){
	    return(0,"ERROR $sbr: wrong format of id=$id in $FileMaxhomRvsdStripBest");
	}
	$val =substr($_,4,8);
	if($val=~/\S\s+\S/){
	    return(0,"ERROR $sbr: wrong format of val=$val in $FileMaxhomRvsdStripBest");
	}

	$id=~s/\s//g; $val=~s/\s//g;
	$h_rvsdBestScores{$id}=$val;
     }
    close FHIN;

#    print "h_rvsdBestScores:\n";
#    foreach $id (sort keys %h_frwdBestScores){ print "$id\t$h_rvsdBestScores{$id}\n"; }

    #now choose best related id for each agape database hit 
    foreach $dbId (keys %h_homID2rank){
	print "\n------$dbId----------\n" if($dbg);
	$dbIdRmsd=$h_id2rmsd{$dbId};
	$dbIdFrwdScore=$h_frwdBestScores{$dbId};
	$dbIdRvsdScore=$h_rvsdBestScores{$dbId};
	print "$dbId dbIdFrwdScore=$dbIdFrwdScore dbIdRvsdScore=$dbIdRvsdScore dbIdRmsd=$dbIdRmsd\n" if($dbg);
	return(0,"ERROR $sbr: rmsd for dbId=$dbId or dbIdFrwdScore=$dbIdFrwdScore or dbIdRvsdScore=$dbIdRvsdScore not defined")
	    if(! defined $dbIdRmsd || ! defined $dbIdFrwdScore || ! defined $dbIdRvsdScore);
	@l_relatedIds=keys %{ $h_dbIds2pdbHomos{$dbId} };
	return(0,"ERROR $sbr: no pdb homologs found for dbId=$dbId (not even self)")
	    if($#l_relatedIds < 0);
	undef %h_frwdLoc; undef %h_rvsdLoc;
	
	foreach $idRelated (@l_relatedIds){
	    $frwdVal               =$h_frwdBestScores{$idRelated};
	    $h_frwdLoc{$idRelated}{'val'} =$frwdVal;

	    $rvsdVal               =$h_rvsdBestScores{$idRelated};
	    $h_rvsdLoc{$idRelated}{'val'} =$rvsdVal;
	    
	    $idRelatedRmsd=$h_id2rmsd{$idRelated};
	    return(0,"ERROR $sbr: rmsd for idRelated=$idRelated not defined")
		if(! defined $idRelatedRmsd);
	    $h_frwdLoc{$idRelated}{'rmsd'} =$idRelatedRmsd;
	    $h_rvsdLoc{$idRelated}{'rmsd'} =$idRelatedRmsd;
	}
	print "FORWARD:\n" if($dbg);
	$bestFrwdId=$dbId; $bestFrwdScore=$dbIdFrwdScore; $bestFrwdRmsd=$dbIdRmsd;
	@l_tmp=sort { $h_frwdLoc{$b}{'val'} <=> $h_frwdLoc{$a}{'val'} } keys %h_frwdLoc;
	foreach $idLoc (@l_tmp){
	    $idRelRmsd=$h_frwdLoc{$idLoc}{'rmsd'};
	    $idRelFrwdScore=$h_frwdLoc{$idLoc}{'val'};
	    print "$idLoc idRelFrwdScore=$idRelFrwdScore  idRelRmsd=$idRelRmsd\n" if($dbg);
	    next if($idRelFrwdScore == $bestFrwdScore && $idRelRmsd == $bestFrwdRmsd);
	    if( ($idRelFrwdScore >= $bestFrwdScore && $idRelRmsd <= $bestFrwdRmsd) ||
		($idRelFrwdScore >  $bestFrwdScore && $idRelRmsd <= 2.0) ){ 
		$bestFrwdId=$idLoc; $bestFrwdScore=$idRelFrwdScore;
		$bestFrwdRmsd=$idRelRmsd;
	    }
	    print "   bestFrwdId=$bestFrwdId bestFrwdScore=$bestFrwdScore bestFrwdRmsd=$bestFrwdRmsd\n" if($dbg);
	}
	return(0,"ERROR $sbr: bestFrwdId for dbId=$dbId not defined")
	    if(! defined $bestFrwdId);
	print "Final: bestFrwdId=$bestFrwdId bestFrwdScore=$bestFrwdScore bestFrwdRmsd=$bestFrwdRmsd\n" if($dbg);
	
	print "REVERSED\n" if($dbg);
	$bestRvsdId=$dbId; $bestRvsdScore=$dbIdRvsdScore; $bestRvsdRmsd=$dbIdRmsd;
	@l_tmp=sort { $h_rvsdLoc{$b}{'val'} <=> $h_rvsdLoc{$a}{'val'} } keys %h_rvsdLoc;
	foreach $idLoc (@l_tmp){
	    $idRelRmsd=$h_rvsdLoc{$idLoc}{'rmsd'};
	    $idRelRvsdScore=$h_rvsdLoc{$idLoc}{'val'};
	    print "$idLoc idRelRvsdScore=$idRelRvsdScore  idRelRmsd=$idRelRmsd\n" if($dbg);
	    next if($idRelRvsdScore == $bestRvsdScore && $idRelRmsd == $bestRvsdRmsd);
	    if( ($idRelRvsdScore >= $bestRvsdScore && $idRelRmsd <= $bestRvsdRmsd) ||
		($idRelRvsdScore >  $bestRvsdScore && $idRelRmsd <= 2.0) ){ 
		$bestRvsdId=$idLoc; $bestRvsdScore=$idRelRvsdScore;
		$bestRvsdRmsd=$idRelRmsd;
	    }
	    print "   bestRvsdId=$bestRvsdId bestRvsdScore=$bestRvsdScore bestRvsdRmsd=$bestRvsdRmsd\n" if($dbg);   
	}
	return(0,"ERROR $sbr: bestRvsdId for dbId=$dbId not defined")
	    if(! defined $bestRvsdId);
	print "FINAL: bestRvsdId=$bestRvsdId bestRvsdScore=$bestRvsdScore bestRvsdRmsd=$bestRvsdRmsd\n" if($dbg);
	$h_homID2rank{$dbId}{'bestFrwdId'} =$bestFrwdId;
	$h_homID2rank{$dbId}{'bestRvsdId'} =$bestRvsdId;
	print "dbId=$dbId  bestFrwdId=$bestFrwdId  bestRvsdId=$bestRvsdId\n" if($dbg);
    }
    undef %h_frwdLoc; undef %h_rvsdLoc;

    #modify id files
    undef %h_bestFrwdIds;
    open(FHIN,$FileFrwdAliIds) ||
	return(0,"ERROR $sbr: failed to open file=$FileFrwdAliIds");
    while(<FHIN>){
	next if(/^\s*$|^\#/);
	($id)=($_=~/^(\S+)/);
	$bestId=$h_homID2rank{$id}{'bestFrwdId'};	
	$h_bestFrwdIds{$bestId}=1;
    }
    close FHIN;

    $FileFrwdAliIdsBest=$FileFrwdAliIds."-best";
    open(FHOUT,">".$FileFrwdAliIdsBest) ||
	return(0,"ERROR $sbr: failed to open fileOut=$FileFrwdAliIdsBest");
    foreach $id (sort keys %h_bestFrwdIds){ print FHOUT $id,"\n" };
    close FHOUT;

    undef %h_bestRvsdIds;
    open(FHIN,$FileRvsdAliIds) ||
	return(0,"ERROR $sbr: failed to open file=$FileRvsdAliIds");
    undef %h_bestRvsdIds;
    while(<FHIN>){
	next if(/^\s*$|^\#/);
	($id)=($_=~/^(\S+)/);
	$bestId=$h_homID2rank{$id}{'bestRvsdId'};
	$h_bestRvsdIds{$bestId}=1;
    }
    close FHIN;

    $FileRvsdAliIdsBest=$FileRvsdAliIds."-best";
    open(FHOUT,">".$FileRvsdAliIdsBest) ||
	return(0,"ERROR $sbr: failed to open fileOut=$FileRvsdAliIdsBest");
    foreach $id (sort keys %h_bestRvsdIds){ print FHOUT $id,"\n" };
    close FHOUT;


    $hsspFrwd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomFrwdHsspBest $FastaInLoc $main::par{pdb_mfasta} $FileFrwdAliIdsBest $FileFrwdMpearson";
    print "executing:\n$hsspFrwd2mpearsonCmd\n"  if($dbg);
    $Lok=system($hsspFrwd2mpearsonCmd);
    return(0,"ERROR $sbr: command=$hsspFrwd2mpearsonCmd failed, stopped")
	if($Lok != 0);

    $hsspRvsd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomRvsdHsspBest $FastaInLoc $main::par{pdb_mfasta} $FileRvsdAliIdsBest $FileRvsdMpearson";
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
    undef %h_mpearson_frwd;
    ($Lok,$msg)=&read_mpearson($FileFrwdMpearson,\%h_mpearson_frwd);
    return(0,"ERROR $sbr: $msg") if(! $Lok);
 
    undef %h_mpearson_rvsd;
    ($Lok,$msg)=&read_mpearson($FileRvsdMpearson,\%h_mpearson_rvsd);
    return(0,"ERROR $sbr: $msg") if(! $Lok);
    
    open(FHOUTMP,">".$FileMpearson) ||
	return(0,"ERROR $sbr: failed to open FileMpearson=$FileMpearson for output, stopped");
    foreach $HomID (sort {$h_homID2rank{$a}{'rank'} <=> $h_homID2rank{$b}{'rank'}} 
		    keys %h_homID2rank ){

	$Pval=$h_homID2rank{$HomID}{'pval'}; 
	$Pval=sprintf "%1.3e", $Pval; $Pval=~s/\s//g;
	$Eval=$h_homID2rank{$HomID}{'eval'};
	$Eval=sprintf "%1.3e", $Eval; $Eval=~s/\s//g;
	$bestDirection=$h_homID2rank{$HomID}{'best'};
	print "HomID=$HomID, bestDirection=$bestDirection\n" if($dbg);
	if($bestDirection eq "frwd"){
	    $bestFrwdId=$h_homID2rank{$HomID}{'bestFrwdId'};
	    print "bestFrwdId=$bestFrwdId\n" if($dbg);
	    return(0,"ERROR $sbr: did not find pearson_frwd for $bestFrwdId")
		if(! defined $h_mpearson_frwd{$bestFrwdId});
	    print FHOUTMP ">".$bestFrwdId."\t"."P-value=".$Pval."\t"."E-value=".$Eval."\n";
	    print FHOUTMP "query\t".$h_mpearson_frwd{$bestFrwdId}{"query"}."\n";
	    print FHOUTMP "$bestFrwdId\t".$h_mpearson_frwd{$bestFrwdId}{"subject"}."\n";
	    
	}elsif($bestDirection eq "rvsd"){
	    $bestRvsdId=$h_homID2rank{$HomID}{'bestRvsdId'};
	    print "bestRvsdId=$bestRvsdId\n" if($dbg);
	    return(0,"ERROR $sbr: did not find pearson_rvsd for $bestRvsdId")
		if(! defined $h_mpearson_rvsd{$bestRvsdId});
	    print FHOUTMP ">".$bestRvsdId."\t"."P-value=".$Pval."\t"."E-value=".$Eval."\n";
	    print FHOUTMP "query\t".$h_mpearson_rvsd{$bestRvsdId}{"query"}."\n";
	    print FHOUTMP "$bestRvsdId\t".$h_mpearson_rvsd{$bestRvsdId}{"subject"}."\n";

	}else{
	   return(0,"ERROR $sbr: did not understand bestDirection=$bestDirection");
       } 
    }
    close FHOUTMP;

    $mpearson2ALmpdbCmd="$main::par{mpearson2ALmpdb_exe} $FileMpearson $FileOutMpdb $FileOutAL $QueryTitle $main::par{max_ali_rank} $main::par{db_relat} $FileParsedCombined";
    print "executing:\n$mpearson2ALmpdbCmd\n"  if($dbg);
    $Lok=system($mpearson2ALmpdbCmd);
    return(0,"ERROR $sbr: command=$mpearson2ALmpdbCmd failed, stopped")
	if($Lok != 0);

    #COMMENTED OUT, was debugging mpearson2ALmpdb, there was some strange hack there cousing different results when run second time, probably mpearson file is somehow modified every time
    #retry 
    #$FileOutMpdbTmp=$FileOutMpdb."-again";
    #$FileOutALTmp=$FileOutAL."-again";
    #$mpearson2ALmpdbCmd="$main::par{mpearson2ALmpdb_exe} $FileMpearson $FileOutMpdbTmp $FileOutALTmp $QueryTitle $main::par{max_ali_rank} $main::par{db_relat} $FileParsedCombined";
    #print "executing:\n$mpearson2ALmpdbCmd\n"  if($dbg);
    #$Lok=system($mpearson2ALmpdbCmd);
    #return(0,"ERROR $sbr: command=$mpearson2ALmpdbCmd failed, stopped")
#	if($Lok != 0);


    $mpearson2shortCmd="$main::par{mpearson2short_exe} $FileMpearson $FileShort $main::par{max_ali_rank} $main::par{db_relat}";
    print "executing:\n$mpearson2shortCmd\n"  if($dbg);
    $Lok=system($mpearson2shortCmd);
    return(0,"ERROR $sbr: command=$mpearson2shortCmd failed, stopped")
	if($Lok != 0);

    #trim mpearson file (remove too low ranks)
    $FileMpearsonTmp=$FileMpearson;
    $FileMpearsonTmp.=".tmpHold";
    open(FHOUTMPEARSONNEW,">".$FileMpearsonTmp) || 
        return(0,"ERROR $sbr: failed to open $FileMpearsonTmp for output, stopped");
    open(FHMPEARSONOLD,$FileMpearson) ||
	return(0,"ERROR $sbr: failed to open $FileMpearson for reading, stopped");
    $ctAliLoc=0;
    while(<FHMPEARSONOLD>){
	if(/^>/){ 
	    $ctAliLoc++; 
	    last if($ctAliLoc > $main::par{max_ali_rank}); 
	    print FHOUTMPEARSONNEW "\n" if($ctAliLoc > 1);
	}
	print FHOUTMPEARSONNEW $_;
    }
    close FHOUTMPEARSONNEW; close FHMPEARSONOLD;
    rename ($FileMpearsonTmp, $FileMpearson) ||
	return(0,"ERROR $sbr: failed to rename $FileMpearsonTmp to $FileMpearson, stopped");

    
    $cmd="\\cp -p $FileMpearson $finalMpearson";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutAL $finalAL";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutMpdb $finalMpdb";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileShort $finalShort";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");
    
    $cmd="\\cp -p $finalMpdb $finalAL $finalMpearson $main::par{results_dir}";
    system($cmd);

    system("cat $FileShort $FileMpearson $FileOutAL $FileOutMpdb");


    
    if(! $dbg){
	unlink ($BlastForProfileTmp,$BlastForProfOut,$BlastMatOut,$FileSaf,$FileSafHssp,$FileSafHsspFilt,$FileProfRdb,$FileQueryDssp,$FileMaxhomFrwdHssp,$FileMaxhomFrwdStrip,$FileMaxhomRvsdHssp,$FileMaxhomRvsdStrip,$FileSeqSecAcc,$FileSssaProfile,"collage-stat.data");
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
