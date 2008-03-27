#! /usr/bin/perl -w

($FastaIn,$FileOutAL,$dbg)=@ARGV;
die "ERROR $0: argument FastaIn not defined, stopped" 
    if(! defined $FastaIn);

if(! defined $dbg){ $dbg=0; }


$par{'HOME'}                  ="/home/$ENV{USER}/server/pub/threader/";
$par{'work_dir'}              =$par{'HOME'}."LOG/";
$par{'scripts'}               =$par{'HOME'}."scr/";
$par{'mat'}                   =$par{'HOME'}."mat/";
$par{'bin'}                   =$par{'HOME'}."bin/";
$par{'blastpgp_exe'}          ="/usr/pub/molbio/blast/blastpgp";
$par{'dsspExtrSeqSecAcc_exe'} =$par{'scripts'}."dsspExtrSeqSecAcc.pl";
$par{'mat2maxsssaprof_exe'}   =$par{'scripts'}."mat2maxsssaprof.pl";
$par{'prof_exe'}              ="/home/rost/pub/prof/scr/prof.pl";
$par{'blast2saf_exe'}         =$par{'scripts'}."blast2saf.pl";
$par{'copf_exe'}              =$par{'scripts'}."copf.pl";
$par{'hssp_filter_exe'}       =$par{'scripts'}."hssp_filter.pl";
$par{'conv_phd2dssp_exe'}     =$par{'scripts'}."conv_phd2dssp.pl";
$par{'maxhom_sssa1_csh_exe'}  =$par{'bin'}."maxhom_sssa1.csh";
$par{'hssp_to_AL_exe'}        =$par{'scripts'}."/hssp_to_AL.pl";

$par{'traindb'}               ="/data/blast/big_98";
$par{'strmat'}                =$par{'mat'}."StrMat.metric";
$par{'maxhom_default'}        =$par{'mat'}."maxhom_default";
#$par{'dssp_templates'}        ="/home/database/pdb61_dssp_short.list";
$par{'dssp_templates'}        ="/data/derived/big/pdb_65.dssp.list";
$par{'log_dir'}               =$par{'HOME'}."LOG/";
$par{'results_dir'}           =$par{'HOME'}."results/";

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
print "SeqName=$SeqName\n";


die "SeqName not defined for file $FastaIn, stopped"
    if(! defined $FastaIn);

$QueryID           =$FastaIn;
$QueryID           =~s/^.*\/|\..*$//g;

if($dbg){ $LogFile  =$QueryID."_threader.log"; }
else{     $LogFile  =$par{'log_dir'}.$QueryID."_threader.log"; 
	  $ErrFile  =$par{'log_dir'}.$QueryID."_threader.err";
}

if(! $dbg){ open(STDERR,">".$ErrFile); 
	    open(STDOUT,">".$LogFile); }

print "INFO: FastaIn=$FastaIn\n";

$BlastForProfOut   =$par{'work_dir'}.$QueryID.".BlastForProf";

$BlastMatOut       =$par{'work_dir'}.$QueryID.".BlastMat";
$BlastForProfileTmp =$par{'work_dir'}.$QueryID.".Blastpgp_tmp";

$FileSaf           =$par{'work_dir'}.$QueryID.".saf";
$FileSafHssp       =$par{'work_dir'}.$QueryID.".hssp";
$FileSafHsspFilt   =$par{'work_dir'}.$QueryID.".hsspFilt";
$FileHsspForProf   =$par{'work_dir'}.$QueryID.".hssp";

$FileProfRdb       =$par{'work_dir'}.$QueryID.".rdbProf";
$FileDssp          =$par{'work_dir'}.$QueryID.".dssp";
$FileSeqSecAcc     =$par{'work_dir'}.$QueryID.".SeqSecAcc";
$FileSssaProfile   =$par{'work_dir'}.$QueryID.".sssa_profile";

$FileMaxhomHssp    =$par{'work_dir'}.$QueryID.".hssp";
$FileMaxhomStrip   =$par{'work_dir'}.$QueryID.".strip";

if(! defined $FileOutAL){ $FileOutAL=$par{'work_dir'}.$QueryID.".AL"; }

#goto there;

$BlastForProfCmd="$par{blastpgp_exe} -i $FastaIn -d $par{traindb} -j 2 -o $BlastForProfOut -e 1 -h 0.001 -v 2500 -b 2500 -a 2";
print "executing:\n$BlastForProfCmd\n"  if($dbg);
$Lok=system($BlastForProfCmd);
die "ERROR: command=$BlastForProfCmd failed, stopped"
    if( ($Lok != 0) || (! -e $BlastForProfOut) );

$BlastToSafCmd="$par{blast2saf_exe} $BlastForProfOut fasta=$FastaIn eSaf=1 maxAli=2500 saf=$FileSaf";
print "executing:\n$BlastToSafCmd\n"  if($dbg);
$Lok=system($BlastToSafCmd);
die "ERROR: command=$BlastToSafCmd failed, stopped"
    if($Lok != 0);


$SafToHsspCmd="$par{copf_exe} $FileSaf $FileSafHssp";
print "executing:\n$SafToHsspCmd\n"  if($dbg);
$Lok=system($SafToHsspCmd);
die "ERROR: command=$SafToHsspCmd failed, stopped"
    if($Lok != 0);


$HsspFilterCmd="$par{hssp_filter_exe} $FileSafHssp fileOut=$FileSafHsspFilt";
print "executing:\n$HsspFilterCmd\n"  if($dbg);
$Lok=system($HsspFilterCmd);
die "ERROR: command=$HsspFilterCmd failed, stopped"
    if($Lok != 0);


unlink $FileSafHssp;
rename $FileSafHsspFilt,$FileHsspForProf;


$ProfCmd="$par{prof_exe} $FileHsspForProf";
print "executing:\n$ProfCmd\n"  if($dbg);
$Lok=system($ProfCmd);
die "ERROR: command=$ProfCmd failed, stopped"
    if($Lok != 0);




$BlastForProfileCmd="$par{blastpgp_exe} -i $FastaIn -d $par{traindb} -j 4 -o $BlastForProfileTmp -Q $BlastMatOut -e 0.001 -h 0.001 -v 2500 -b 2500 -a 2";
print "executing:\n$BlastForProfileCmd\n"  if($dbg);
$Lok=system($BlastForProfileCmd);
die "ERROR: command=$BlastForProfileCmd failed, stopped"
    if( ($Lok != 0) || (! -e $BlastForProfileTmp) );

#if(! $dbg){ unlink $BlastForProfileTmp; };


$conv_phd2dsspCmd="$par{conv_phd2dssp_exe} $FileProfRdb fileOut=$FileDssp";
print "executing:\n$conv_phd2dsspCmd\n"  if($dbg);
$Lok=system($conv_phd2dsspCmd);
die "ERROR: command=$conv_phd2dsspCmd failed, stopped"
    if($Lok != 0);



$DsspExtrSeqSecAccCmd="$par{dsspExtrSeqSecAcc_exe} $FileDssp fileOut=$FileSeqSecAcc";
print "executing:\n$DsspExtrSeqSecAccCmd\n"  if($dbg);
$Lok=system($DsspExtrSeqSecAccCmd);
die "ERROR: command=$DsspExtrSeqSecAccCmd failed, stopped"
    if($Lok != 0);

#there:

$mat2maxsssaprofCmd="$par{mat2maxsssaprof_exe} $BlastMatOut filesec=$FileSeqSecAcc strmat=$par{strmat}";
print "executing:\n$mat2maxsssaprofCmd\n"  if($dbg);
$Lok=system($mat2maxsssaprofCmd);
die "ERROR: command=$mat2maxsssaprofCmd failed, stopped"
    if($Lok != 0);



$Maxhom_sssa1Cmd="$par{maxhom_sssa1_csh_exe} $FileSssaProfile $par{dssp_templates}";
print "executing:\n$Maxhom_sssa1Cmd\n"  if($dbg);
$Lok=system($Maxhom_sssa1Cmd);
die "ERROR: command=$Maxhom_sssa1Cmd failed, stopped"
    if($Lok != 0);


$hssp_to_AL_exeCmd="$par{hssp_to_AL_exe} $FastaIn $FileMaxhomHssp $FileMaxhomStrip $FileOutAL $SeqName $dbg";
print "executing:\n$hssp_to_AL_exeCmd\n"  if($dbg);
$Lok=system($hssp_to_AL_exeCmd);
die "ERROR: command=$hssp_to_AL_exeCmd failed, stopped"
    if($Lok != 0);


if(! $dbg){
    unlink ($BlastForProfileTmp,$BlastForProfOut,$BlastMatOut,$FileDssp,$FileMaxhomHssp,$FileMaxhomStrip,$FileProfRdb,$FileSaf,$FileSeqSecAcc,$FileSssaProfile,"collage-stat.data");
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
