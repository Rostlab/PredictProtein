#parameters for threader

$par{'HOME'}                  ="/home/dudek/server/pub/agape/";
$par{'work_dir'}              =$par{'HOME'}."WORK/";
$par{'scripts'}               =$par{'HOME'}."scr/";
$par{'mat'}                   =$par{'HOME'}."mat/";
$par{'bin'}                   =$par{'HOME'}."bin/";
$par{'resources'}             =$par{'HOME'}."resources/";


$par{'maxhom_binary'}         =$par{'bin'}."my_maxhom.LINUX";


#$par{'prof_exe'}              ="/home/$ENV{USER}/server/pub/prof/scr/prof.pl";
$par{'prof_exe'}              ="/home/rost/pub/prof/prof";
#$par{'prof_dir'}              =$ENV{"PROF"};
#$par{'prof_dir'}             .="/" if($par{'prof_dir'} !~/\/$/);
#$par{'prof_exe'}              =$par{'prof_dir'}."prof";

$par{'agape_pack'}            =$par{'scripts'}."pack/"."agape.pm";


$par{'blastpgp_exe'}          =$par{'resources'}."blast/blastpgp";
$par{'hssp_filter_exe'}       =$par{'resources'}."hssp_filter/hssp_filter.pl";
$par{'copf_exe'}              =$par{'resources'}."copf/copf.pl";
$par{'saf_filter_exe'}        =$par{'resources'}."saf_filter/safFilterRed.pl";

$par{'conv_phd2dssp_exe'}     =$par{'scripts'}."conv_phd2dssp.pl";
$par{'dsspExtrSeqSecAcc_exe'} =$par{'scripts'}."dsspExtrSeqSecAcc.pl";
$par{'mat2maxsssaprof_exe'}   =$par{'scripts'}."BmatPhdStSt2sssa.pl";
$par{'blast2saf_exe'}         =$par{'scripts'}."blast2saf.pl";
$par{'maxhom_frwd_exe'}       =$par{'scripts'}."maxhom_frwd.pl";
$par{'maxhom_rvsd_exe'}       =$par{'scripts'}."maxhom_rvsd.pl";
$par{'hssp_to_AL_exe'}        =$par{'scripts'}."hssp_to_AL.pl";
$par{'strip_to_list_exe'}     =$par{'scripts'}."strip_to_list.pl";
$par{'parseStripFrwd_exe'}    =$par{'scripts'}."parseStripFrwd.pl";
$par{'parseStripRvsd_exe'}    =$par{'scripts'}."parseStripRvsd.pl";
$par{'frwdRvsdScore_exe'}     =$par{'scripts'}."frwdRvsdScoring.pl"; 
$par{'hssp2mpearson_exe'}     =$par{'scripts'}."hssp2mpearson.pl";
$par{'mpearson2ALmpdb_exe'}   =$par{'scripts'}."mpearson2pdb.pl";
$par{'mpearson2short_exe'}    =$par{'scripts'}."mpearson2short.pl";

$par{'traindb'}               =$par{"mat"}."big_80"; #/data/blast/big_98";
$par{'strmat'}                =$par{'mat'}."StrMat.metric";
$par{'maxhom_default'}        =$par{'mat'}."maxhom.default";
#print "WARNING:  THIS IS A DEBUG VERSION OPERATING WITH SHORT DATABASES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
$par{'db_dssp_list'}          =$par{'mat'}."db_dssp.list";
$par{'db_sssa_list'}          =$par{'mat'}."db_sssa.list";

$par{'file_dbIds2allpdb_dssp'}   =$par{'mat'}."dbIds2allpdb_dssp.dat";
$par{'file_dbIds2allpdb_sssa'}   =$par{'mat'}."dbIds2allpdb_sssa.dat";

$par{'db_stat'}               =$par{'mat'}."db_stat.dat";
$par{'db_relat'}              =$par{'mat'}."homol_hssp0.dat"; #agape db relationships
$par{'db_mfasta'}             =$par{'mat'}."db.mfasta";
$par{'pdb_mfasta'}            =$par{'mat'}."pdb.mfasta";
$par{'dbIds2pdbHomos'}        =$par{'mat'}."dbIds2pdbHomoIds.dat";
$par{'file_pdbRmsd'}          =$par{'mat'}."pdb_resolution.dat";

$par{'db_pdb_dir'}            ="/data/dssp_pred/pdb/pdbs/";


$par{'max_ali_rank'}          =5;

$par{'log_dir'}               =$par{'HOME'}."LOG/";
$par{'results_dir'}           =$par{'HOME'}."results/";

1;
