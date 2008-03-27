#parameters for unique list


$par{"home_agape"}="/home/dudek/server/pub/agape/";

$par{"lr_pdb_dirs"}=["/data/pdb/","/data/pdb_obsolete/","/data/pdb_theory/"];
$par{"home_db_scr"}="/home/dudek/server/pub/agape/scr/db_update/";

$par{"pdb2fasta_exe"}        =$par{'home_db_scr'}."pdb2fasta_my.pl";
$par{"procMfasta_exe"}       =$par{'home_db_scr'}."processMfasta.pl";
$par{"mfasta2lengths_exe"}   =$par{'home_db_scr'}."mfasta2lengths.pl";
$par{"runBlast_exe"}         =$par{'home_db_scr'}."runBlast.pl";
$par{"blastm9ToUniRdb_exe"}  =$par{'home_db_scr'}."blastm9ToUniRdb.pl";
$par{"concRdbs_exe"}         =$par{'home_db_scr'}."concRdbs.pl";
$par{"pdbid2exclude_exe"}    =$par{'home_db_scr'}."pdbid2exclude.pl";
$par{"pdbid2resolution_exe"} =$par{'home_db_scr'}."pdbid2resolution.pl";
$par{"pdbid2type_exe"}       =$par{'home_db_scr'}."pdbid2type.pl";
$par{"mrdb2unique_exe"}      =$par{'home_db_scr'}."Rdb2UniqueList.pl_lowmem";

$par{"blastpgp_exe"}         =$par{"home_agape"}."blast/blastpgp";
$par{"blast2saf_exe"}        =$par{"home_agape"}."scr/"."blast2saf.pl";
$par{"copf_exe"}             =$par{"home_agape"}."scr/"."copf.pl";
$par{"hssp_filter_exe"}      =$par{"home_agape"}."scr/"."hssp_filter.pl";
$par{"prof_exe"}             ="/home/rost/pub/prof/prof";

$par{"traindb"}          =$par{"home_agape"}."mat/big_80";;

$par{"minlen"}           =30;
$par{"maxUnkFrac"}       =0.1;
$par{'unk_resolution'}   =99;    #resolution to enter if format is not recognized
$par{'NMR_resolution'}   =9.999;      #resolution to enter if RESOLUTION. NOT APPLICABLE

1;
