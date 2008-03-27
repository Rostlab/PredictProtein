package agape;

sub run_agape{
    print "!!!!!!!!!!!!! fix P-values so that combining them makes some sense\n";
    my $sbr="run_agape";
    my ($configFile,$FastaIn,$db_dssp_list,$db_sssa_list,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$jobID,$dbg)=@_;
    return(0,"ERROR $sbr: arguments not defined, stopped")
	if(! defined $configFile      || ! defined $FastaIn         ||
	   ! defined $db_dssp_list    || ! defined $db_sssa_list ||
	   ! defined $finalMpearson   || ! defined $finalAL         || 
	   ! defined $finalMpdb       || ! defined $jobID);
   
   
    if(! defined $dbg){ $dbg=0; }
    
    print "debug on !!!\n" if($dbg);
    #require $configFile == 1 || 
#	return(0,"ERROR $sbr: failed to require config file: $configFile, stopped");#

#    print "parameters:\n";
#    foreach $key (sort keys %main::par){ print "par key: $key\n"; }
    
    open(FHINLOC,$db_dssp_list) || 
	return(0,"ERROR failed to open db_dssp_list=$db_dssp_list, stopped");
    while(<FHINLOC>){
	next if(/^\s*|^\#/);
	s/\s*$//; $file=$_;
	s/^.*\///; s/\..*//;
	$h_dssp_db_ids{$_}=$file;
    }
    close FHINLOC;

    open(FHINLOC,$db_sssa_list) || 
	return(0,"ERROR failed to open db_sssa_list=$db_sssa_list, stopped");
    while(<FHINLOC>){
	next if(/^\s*|^\#/);
	s/\s*$//; $file=$_;
	s/^.*\///; s/\..*//;
	$h_sssa_db_ids{$_}=$file;
    }
    close FHINLOC;

    #check if there are the same ids in both databases
    foreach $id (keys %h_dssp_ids){ 
	return(0,"ERROR: databases $db_dssp_list and $db_sssa_list do not contain the same ids, stopped")
	    if(! defined $h_profile_list{$id});
    }
    foreach $id (keys %h_sssa_ids){ 
	return(0,"ERROR: databases $db_dssp_list and $db_sssa_list do not contain the same ids, stopped")
	    if(! defined $h_dssp_list{$id});
    }

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
	if(! -e $db_dssp_list);
    return(0,"maxhom sssa database $par{db_sssa_list} not found, stopped")
	if(! -e $db_sssa_list);

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
    $FileLong             =$work_dir_loc.$QueryID.".long";

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


    $Maxhom_frwdCmd="$main::par{maxhom_frwd_exe} $FileSssaProfile $db_dssp_list $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_frwdCmd\n"  if($dbg);
    $Lok=system($Maxhom_frwdCmd);
    return(0,"ERROR $sbr: command=$Maxhom_frwdCmd failed, stopped")
	if($Lok != 0);


    $Maxhom_rvsdCmd="$main::par{maxhom_rvsd_exe} $FileQueryDssp $db_sssa_list $FileMaxhomRvsdHssp $FileMaxhomRvsdStrip $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_rvsdCmd\n"  if($dbg);
    $Lok=system($Maxhom_rvsdCmd);
    return(0,"ERROR $sbr: command=$Maxhom_rvsdCmd failed, stopped")
	if($Lok != 0);

    print "dbg=$dbg after maxhom_rvsd\n";

    $K_evd      =$main::par{'K_evd'};
    $lambda_evd =$main::par{'lambda_evd'};
    return(0,"ERROR: distribution parameters not defined: K_evd=$K_evd lambda_evd=$lambda_evd, stopped") if(! defined $K_evd || ! defined $lambda_evd);

    $db_residue_ct =$main::par{'db_residue_ct'};
    return(0,"ERROR: db_residue_ct not defined, stopped") if(! defined $db_residue_ct);

    $parseStripFrwdCmd="$main::par{parseStripFrwd_exe} $FileMaxhomFrwdStrip $db_dssp_list $K_evd $lambda_evd $db_residue_ct";
    print "executing:\n$parseStripFrwdCmd\n"  if($dbg);
    $Lok=system($parseStripFrwdCmd);
    return(0,"ERROR $sbr: command=$parseStripFrwdCmd failed, stopped")
	if($Lok != 0);

    $parseStripRvsdCmd="$main::par{parseStripRvsd_exe} $FileMaxhomRvsdStrip $db_sssa_list $K_evd $lambda_evd $db_residue_ct";
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
	    $h_homID2rank{$HomID}{'bestFrwdId'}=$HomID; #just a hack
	    print FHOUTFRWDLOC $HomID."\n"; 
	}elsif($better eq "rvsd"){ 
	    $h_homID2rank{$HomID}{'best'}="rvsd";
	    $h_homID2rank{$HomID}{'bestRvsdId'}=$HomID; #just another hack
	    print FHOUTRVSDLOC $HomID."\n"; 
	}else{ return(0,"ERROR $sbr: indicator=$better is not frwd or rvsd, stopped"); }

	last if($rank >= $maxRankLoc);
    }
    close FHOUTFRWDLOC; close FHOUTRVSDLOC;


    $tmp=$db_dssp_list; $tmp=~s/^.*\///;
    $FileSeqSecAccDb="seqSecAccDat-".$tmp;
    $FileMfastaDb="mf-".$tmp;
    #get mfasta of database sequences
    $DsspExtrSeqSecAccCmd2="$main::par{dsspExtrSeqSecAcc_exe} $db_dssp_list fileOut=$FileSeqSecAccDb";
    print "executing:\n$DsspExtrSeqSecAccCmd2\n"  if($dbg);
    $Lok=system($DsspExtrSeqSecAccCmd2);
    return(0,"ERROR $sbr: command=$DsspExtrSeqSecAccCmd2 failed, stopped")
	if($Lok != 0);

    undef %h_dbMfastaLoc;
    open(FHINLOC,$FileSeqSecAccDb) || 
	return(0,"ERROR $sbr: failed to open file=$FileSeqSecAccDb, stopped");
    while(<FHINLOC>){
	next if(/^\s*$|^id\s|^\#/);
	s/\s*$//;
	($idLoc,$lenLoc,$seq,$sec,$acc)=split(/\s+/,$_);
	$h_dbMfastaLoc{$idLoc}=$seq;
    }
    close FHINLOC;
    open(FHOUTLOC,">".$FileMfastaDb) ||
	return(0,"ERROR $sbr: failed to open for output file=$FileMfastaDb, stopped");
    foreach $idLoc (sort keys %h_dbMfastaLoc){
	print FHOUTLOC ">".$idLoc."\n";
	print FHOUTLOC $h_dbMfastaLoc{$idLoc}."\n";
    }
    close FHOUTLOC;

 
    $hsspFrwd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomFrwdHssp $FastaInLoc $FileMfastaDb $FileFrwdAliIds $FileFrwdMpearson";
    print "executing:\n$hsspFrwd2mpearsonCmd\n"  if($dbg);
    $Lok=system($hsspFrwd2mpearsonCmd);
    return(0,"ERROR $sbr: command=$hsspFrwd2mpearsonCmd failed, stopped")
	if($Lok != 0);

    $hsspRvsd2mpearsonCmd="$main::par{hssp2mpearson_exe} $FileMaxhomRvsdHssp $FastaInLoc $FileMfastaDb $FileRvsdAliIds $FileRvsdMpearson";
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


    $mpearson2shortCmd="$main::par{mpearson2short_exe} $FileMpearson $FileShort $FileLong $main::par{max_ali_rank} $main::par{db_relat}";
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

    
    $cmd="\\cp -p $FileLong $finalMpearson";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutAL $finalAL";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileOutMpdb $finalMpdb";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");

    $cmd="\\cp -p $FileShort $finalShort";
    system($cmd)==0 || return(0,"ERROR $sbr: failed on $cmd, stopped");
    
    #$cmd="\\cp -p $finalMpdb $finalAL $finalMpearson $finalShort $main::par{results_dir}";
    #system($cmd);

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
