#parameters for threader

$par{'HOME'}                  ="/home/$ENV{USER}/server/pub/threader/";
$par{'work_dir'}              =$par{'HOME'}."LOG/";
$par{'scripts'}               =$par{'HOME'}."scr/";
$par{'mat'}                   =$par{'HOME'}."mat/";
$par{'bin'}                   =$par{'HOME'}."bin/";
$par{'blastpgp_exe'}          ="/usr/pub/molbio/blast/blastpgp";
$par{'dsspExtrSeqSecAcc_exe'} =$par{'scripts'}."dsspExtrSeqSecAcc.pl";
$par{'mat2maxsssaprof_exe'}   =$par{'scripts'}."mat2maxsssaprof.pl";
$par{'prof_exe'}              ="/home/$ENV{USER}/server/pub/prof/scr/prof.pl";
$par{'blast2saf_exe'}         =$par{'scripts'}."blast2saf.pl";
$par{'copf_exe'}              =$par{'scripts'}."copf.pl";
$par{'hssp_filter_exe'}       =$par{'scripts'}."hssp_filter.pl";
$par{'conv_phd2dssp_exe'}     =$par{'scripts'}."conv_phd2dssp.pl";
$par{'maxhom_sssa1_csh_exe'}  =$par{'bin'}."maxhom_sssa1.csh";
$par{'maxhom_topits_csh_exe'} =$par{'bin'}."maxhom_topits.csh";
$par{'hssp_to_AL_exe'}        =$par{'scripts'}."hssp_to_AL.pl";
$par{'strip_to_list_exe'}     =$par{'scripts'}."strip_to_list.pl";

$par{'traindb'}               ="/data/blast/big_98";
$par{'strmat'}                =$par{'mat'}."StrMat.metric";
$par{'maxhom_default'}        =$par{'mat'}."maxhom_default";
$par{'dssp_templates'}        ="/data/derived/big/pdb_65.dssp.list";
$par{'log_dir'}               =$par{'HOME'}."LOG/";
$par{'results_dir'}           =$par{'HOME'}."results/";

1;
