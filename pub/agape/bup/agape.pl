#! /usr/bin/perl -w

($FastaIn,$FileOutAL,$dbg)=@ARGV;
die "ERROR $0: argument FastaIn not defined, stopped" 
    if(! defined $FastaIn);

$DoublePass=0;

if(! defined $dbg){ $dbg=0; }

$configFile                   ="/home/$ENV{USER}/server/pub/agape/config/config.pm";

require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

$pathLoc=`pwd`;
$pathLoc=~s/\s//g; 
$pathLoc.="/" if($pathLoc !~ /\/$/);

if($FastaIn !~ /\//){ $FastaIn=$pathLoc.$FastaIn; }
if($FileOutAL !~ /\//){ $FileOutAL=$pathLoc.$FileOutAL; }

chdir ($par{'work_dir'}) || 
    die "ERROR: failed to chdir to par{work_dir}=$par{work_dir}, stopped";

open(FHFASTAIN,$FastaIn) || 
    die "failed to open FastaIn=$FastaIn, stopped";
while(<FHFASTAIN>){
    if(/^>/){
	s/^>\s*\S*\s*\(\#\)\s*//;
	($SeqName)=/^(\S+)/;
	$SeqName=~s/\||>//g;
    }
}
close FHFASTAIN;

die "SeqName not defined for file $FastaIn, stopped"
    if(! defined $FastaIn);

$QueryID           =$FastaIn;
$QueryID           =~s/^.*\/|\..*$//g;

if($dbg){ $LogFile  =$QueryID."_agepe.log"; }
else{     $LogFile  =$par{'log_dir'}.$QueryID."_agape.log"; 
	  $ErrFile  =$par{'log_dir'}.$QueryID."_agape.err";
}

if(! $dbg){ open(STDERR,">".$ErrFile); 
	    open(STDOUT,">".$LogFile); }

print "INFO: SeqName=$SeqName\n";
print "INFO: FastaIn=$FastaIn\n";

#get number of proteins in the maxhom database files
die "maxhom dssp database $par{db_dssp_list} not found, stopped"
    if(! -e $par{'db_dssp_list'});
die "maxhom sssa database $par{db_sssa_list} not found, stopped"
    if(! -e $par{'db_sssa_list'});

$BlastForProfOut      =$par{'work_dir'}.$QueryID.".BlastForProf";

$BlastMatOut          =$par{'work_dir'}.$QueryID.".BlastMat";
$BlastForProfileTmp   =$par{'work_dir'}.$QueryID.".Blastpgp_tmp";

$FileSaf              =$par{'work_dir'}.$QueryID.".saf";
$FileSafHssp          =$par{'work_dir'}.$QueryID.".hsspFromSaf";
$FileSafHsspFilt      =$par{'work_dir'}.$QueryID.".hsspFromSafFilt";
#$FileHsspForProf      =$par{'work_dir'}.$QueryID.".hssp";

$FileProfRdb          =$par{'work_dir'}.$QueryID.".rdbProf";
$FileQueryDssp             =$par{'work_dir'}.$QueryID.".dssp";
$FileSeqSecAcc        =$par{'work_dir'}.$QueryID.".SeqSecAcc";
$FileSssaProfile      =$par{'work_dir'}.$QueryID.".sssa_profile";

$FileMaxhomFrwdHssp   =$par{'work_dir'}.$QueryID.".hssp-frwd";
$FileMaxhomFrwdStrip  =$par{'work_dir'}.$QueryID.".strip-frwd";
$FileMaxhomRvsdHssp   =$par{'work_dir'}.$QueryID.".hssp-rvsd";
$FileMaxhomRvsdStrip  =$par{'work_dir'}.$QueryID.".strip-rvsd";
$FileMaxhom2passList  =$par{'work_dir'}.$QueryID.".2pass.list"; 

if(! defined $FileOutAL){ $FileOutAL=$par{'work_dir'}.$QueryID.".AL"; }



$BlastForProfCmd="$par{blastpgp_exe} -i $FastaIn -d $par{traindb} -j 2 -o $BlastForProfOut -e 1 -h 0.1 -v 5000 -b 5000 -a 2";
print "executing:\n$BlastForProfCmd\n"  if($dbg);
$Lok=system($BlastForProfCmd);
die "ERROR: command=$BlastForProfCmd failed, stopped"
    if( ($Lok != 0) || (! -e $BlastForProfOut) );

$BlastToSafCmd="$par{blast2saf_exe} $BlastForProfOut fasta=$FastaIn eSaf=1 maxAli=5000 saf=$FileSaf";
print "executing:\n$BlastToSafCmd\n"  if($dbg);
$Lok=system($BlastToSafCmd);
die "ERROR: command=$BlastToSafCmd failed, stopped"
    if($Lok != 0);


$SafToHsspCmd="$par{copf_exe} $FileSaf fileOut=$FileSafHssp hssp";
print "executing:\n$SafToHsspCmd\n"  if($dbg);
$Lok=system($SafToHsspCmd);
die "ERROR: command=$SafToHsspCmd failed, stopped"
    if($Lok != 0);

$HsspFilterCmd="$par{hssp_filter_exe} $FileSafHssp fileOut=$FileSafHsspFilt red=80";
print "executing:\n$HsspFilterCmd\n"  if($dbg);
$Lok=system($HsspFilterCmd);
die "ERROR: command=$HsspFilterCmd failed, stopped"
    if($Lok != 0);



$ProfCmd="$par{prof_exe} $FileSafHsspFilt fileOut=$FileProfRdb";
print "executing:\n$ProfCmd\n"  if($dbg);
$Lok=system($ProfCmd);
die "ERROR: command=$ProfCmd failed, stopped"
    if($Lok != 0);


$BlastForProfileCmd="$par{blastpgp_exe} -i $FastaIn -d $par{traindb} -j 5 -o $BlastForProfileTmp -Q $BlastMatOut -e 0.1 -h 0.1 -v 2500 -b 2500 -a 2";
print "executing:\n$BlastForProfileCmd\n"  if($dbg);
$Lok=system($BlastForProfileCmd);
die "ERROR: command=$BlastForProfileCmd failed, stopped"
    if( ($Lok != 0) || (! -e $BlastForProfileTmp) );


$conv_phd2dsspCmd="$par{conv_phd2dssp_exe} $FileProfRdb fileOut=$FileQueryDssp";
print "executing:\n$conv_phd2dsspCmd\n"  if($dbg);
$Lok=system($conv_phd2dsspCmd);
die "ERROR: command=$conv_phd2dsspCmd failed, stopped"
    if($Lok != 0);



$DsspExtrSeqSecAccCmd="$par{dsspExtrSeqSecAcc_exe} $FileQueryDssp fileOut=$FileSeqSecAcc";
print "executing:\n$DsspExtrSeqSecAccCmd\n"  if($dbg);
$Lok=system($DsspExtrSeqSecAccCmd);
die "ERROR: command=$DsspExtrSeqSecAccCmd failed, stopped"
    if($Lok != 0);



$mat2maxsssaprofCmd="$par{mat2maxsssaprof_exe} $BlastMatOut rdbphd=$FileProfRdb strmat=$par{strmat}";
print "executing:\n$mat2maxsssaprofCmd\n"  if($dbg);
$Lok=system($mat2maxsssaprofCmd);
die "ERROR: command=$mat2maxsssaprofCmd failed, stopped"
    if($Lok != 0);



$Maxhom_frwdCmd="$par{maxhom_frwd_exe} $FileSssaProfile $par{db_dssp_list} $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $par{work_dir} 0 11 1 $dbg";
print "executing:\n$Maxhom_frwdCmd\n"  if($dbg);
$Lok=system($Maxhom_frwdCmd);
die "ERROR: command=$Maxhom_frwdCmd failed, stopped"
    if($Lok != 0);

$Maxhom_rvsdCmd="$par{maxhom_rvsd_exe} $FileQueryDssp $par{db_sssa_list} $FileMaxhomRvsdHssp $FileMaxhomRvsdStrip $par{work_dir} 0 11 1 $dbg";
print "executing:\n$Maxhom_rvsdCmd\n"  if($dbg);
$Lok=system($Maxhom_rvsdCmd);
die "ERROR: command=$Maxhom_rvsdCmd failed, stopped"
    if($Lok != 0);



if($DoublePass){

    $strip_to_listCmd="$par{strip_to_list_exe} $FileMaxhomStrip $FileMaxhom2passList 20 $dbg";
    print "executing:\n$strip_to_listCmd\n"  if($dbg);
    $Lok=system($strip_to_listCmd);
    die "ERROR: command=$strip_to_listCmd failed, stopped"
	if($Lok != 0);


    $Maxhom_topitsCmd="$par{maxhom_topits_csh_exe} $FileQueryDssp $FileMaxhom2passList";
    print "executing:\n$Maxhom_topitsCmd\n"  if($dbg);
    $Lok=system($Maxhom_topitsCmd);
    die "ERROR: command=$Maxhom_topitsCmd failed, stopped"
	if($Lok != 0);
}


$hssp_to_AL_exeCmd="$par{hssp_to_AL_exe} $FastaIn $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $FileOutAL $SeqName $dbg";
print "executing:\n$hssp_to_AL_exeCmd\n"  if($dbg);
$Lok=system($hssp_to_AL_exeCmd);
die "ERROR: command=$hssp_to_AL_exeCmd failed, stopped"
    if($Lok != 0);


if(! $dbg){
    unlink ($BlastForProfileTmp,$BlastForProfOut,$BlastMatOut,$FileSaf,$FileSafHssp,$FileSafHsspFilt,$FileProfRdb,$FileQueryDssp,$FileMaxhomFrwdHssp,$FileMaxhomFrwdStrip,$FileMaxhomRvsdHssp,$FileMaxhomRvsdStrip,$FileSeqSecAcc,$FileSssaProfile,"collage-stat.data");
}
   
$cmd="cp -p $FileOutAL $FastaIn $par{results_dir}";
system($cmd);

unlink $ErrFile;
print "Output in $FileOutAL\n";
print "threader done :) \n";

#$Cmd="";
#$Lok=system();
#die "ERROR: command= failed, stopped"
#    if($Lok != 0);


#die  "died as required, stopped";
