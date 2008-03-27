#! /usr/bin/perl -w

($fasta,$dirRdbOut,$dbg)=@ARGV;
die "ERROR $0: argument fasta not defined, stopped" 
    if(! defined $fasta || 
       ! defined $dirRdbOut);

$dirRdbOut.="/" if($dirRdbOut !~ /\/$/);
if(! defined $dbg){ $dbg=0; }

$configFile         ="/home/dudek/server/pub/agape/scr/agape_config.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

$pathLoc=`pwd`;
$pathLoc=~s/\s//g; 
$pathLoc.="/" if($pathLoc !~ /\/$/);

if($fasta=~/\.list/){
    open(FHIN,$fasta) || die "did not open fasta=$fasta, stopped";
    while(<FHIN>){
        next if(/^\s*$|^\#/);
        s/\s//g;
	if($_!~/.*\//){ $_=$pathLoc.$_; }
        $h_fastasIn{$_}=1;
    }
    close FHIN;
}else{ 
    if($fasta!~/.*\//){ $fasta=$pathLoc.$fasta; }
    $h_fastasIn{$fasta}=1; 
}


$work_dir_loc="./";

#chdir ($work_dir_loc) || 
#	die "ERROR: failed to chdir to work_dir_loc=$work_dir_loc, stopped";

$tmp=$fasta; $tmp=~s/^.*\///g;
$LogFile =$tmp.".log-".$$;
$ErrFile =$tmp.".err-".$$;
$tmp=`pwd`; print "info: local dir=$tmp\n";
print "info: LogFile=$LogFile ErrFile=$ErrFile\n";
if(! $dbg){ open(STDERR,">".$ErrFile); 
	    open(STDOUT,">".$LogFile); }

foreach $fastaIn (sort keys %h_fastasIn){
    $QueryName       =$fastaIn;
    $QueryName       =~s/^.*\/|\..*$//g;
    
    #$FastaInLoc="query.f";  $QueryID="query";
    $QueryID=$QueryName;
    $FastaInLoc=$fastaIn; #$FastaInLoc=~s/^.*\///; 

    $BlastForProfOut      =$work_dir_loc.$QueryID.".BlastForProf";
    
    #$BlastRdb             =$dirRdbOut.$QueryID.".blast-rdb";
    $BlastMatOut          =$work_dir_loc.$QueryID.".BlastMat";
    #$BlastForProfileTmp   =$work_dir_loc.$QueryID.".Blastpgp_tmp";
    
    
    $FileSaf              =$work_dir_loc.$QueryID.".saf-orig";
    $FileSafFilt          =$work_dir_loc.$QueryID.".saf";
    $FileSafHssp          =$work_dir_loc.$QueryID.".hsspFromSaf";
    $FileSafHsspFilt      =$work_dir_loc.$QueryID.".hsspFromSafFilt";
    #$FileHsspForProf      =$work_dir_loc.$QueryID.".hssp";
    
    $FileProfRdb          =$dirRdbOut.$QueryID.".rdbProf";
    #$FileQueryDssp        =$work_dir_loc.$QueryID.".dssp";
    #$FileSeqSecAcc        =$work_dir_loc.$QueryID.".SeqSecAcc";
    #$FileSssaProfile      =$work_dir_loc.$QueryID.".sssa_profile";
    
    $BlastForProfCmd="$par{blastpgp_exe} -i $FastaInLoc -d $par{traindb} -j 2 -o $BlastForProfOut -e 1 -h 0.1 -v 4000 -b 4000";
    print "executing:\n$BlastForProfCmd\n"  if($dbg);
    $Lok=system($BlastForProfCmd);
    if( ($Lok != 0) || (! -e $BlastForProfOut) ){
	if(! $dbg){
	    print "ERROR: command=$BlastForProfCmd failed\n";
	    unlink $BlastForProfOut;
	    next;
	}else{ die "ERROR: command=$BlastForProfCmd failed, stopped"; }
    }


    $qSeqTmp="";
    open(FHINTMP,$fastaIn) ||
	die "failed to open fastaIn=$fastaIn, stopped";
    while(<FHINTMP>){
	next if(/^>|^\s*$/);
	s/\n//; $qSeqTmp.=$_;
    }
    close FHINTMP;
    $qSeqTmp=~s/\s//g;
    $qLenTmp   =length($qSeqTmp);
    $maxAliRes =500000; #keep below so that copf and hssp_filter won't fail
    $maxAliTmp =int($maxAliRes/$qLenTmp);
    
    print "maxAliTmp: $maxAliTmp\n";
    $BlastToSafCmd="$par{blast2saf_exe} $BlastForProfOut fasta=$FastaInLoc eSaf=1 maxAli=$maxAliTmp saf=$FileSaf"; # rdb=$BlastRdb";
    print "executing:\n$BlastToSafCmd\n"  if($dbg);
    $Lok=system($BlastToSafCmd);
    if($Lok != 0){
	if(! $dbg){
	    print "command=$BlastToSafCmd failed\n";
	    unlink ($FileSaf,$BlastForProfOut);
	    next;
	}else{ die "ERROR: command=$BlastToSafCmd failed, stopped"; }
    }
    
    $SafFilterCmd="$par{saf_filter_exe} $FileSaf fileOut=$FileSafFilt red=80";
    print "executing:\n$SafFilterCmd\n"  if($dbg);
    $Lok=system($SafFilterCmd);
    if($Lok != 0){
	if(! $dbg){
	    print "ERROR: command=$SafFilterCmd failed\n";
	    unlink ($FileSaf,$BlastForProfOut,$FileSafFilt);
	}else{ die "ERROR: command=$SafFilterCmd failed, stopped" }
    }
    
    
    $SafToHsspCmd="$par{copf_exe} $FileSafFilt fileOut=$FileSafHssp hssp";
    print "executing:\n$SafToHsspCmd\n"  if($dbg);
    $Lok=system($SafToHsspCmd);
    if($Lok != 0){
	if(! $dbg){
	    print "ERROR: command=$SafToHsspCmd failed\n";
	    unlink ($FileSafHssp,$FileSaf,$BlastForProfOut,$FileSafFilt);
	    next;
	}else{ die "ERROR: command=$SafToHsspCmd failed, stopped"; }
    }


   # $HsspFilterCmd="$par{hssp_filter_exe} $FileSafHssp fileOut=$FileSafHsspFilt red=80";
   # print "executing:\n$HsspFilterCmd\n"  if($dbg);
   # $Lok=system($HsspFilterCmd);
   # die "ERROR: command=$HsspFilterCmd failed, stopped"
#	if($Lok != 0);
    
    
    $ProfCmd="$par{prof_exe} $FileSafHssp  fileOut=$FileProfRdb";
    print "executing:\n$ProfCmd\n"  if($dbg);
    $Lok=system($ProfCmd);
    if($Lok != 0){
	if(! $dbg){
	    print "ERROR: command=$ProfCmd failed\n";
	    unlink ($FileSafHssp,$FileSaf,$BlastForProfOut,$FileSafFilt);
	    next;
	}else{ die "ERROR: command=$ProfCmd failed, stopped"; }
    }
    
#    $conv_phd2dsspCmd="$par{conv_phd2dssp_exe} $FileProfRdb fileOut=$FileQueryDssp";
#    print "executing:\n$conv_phd2dsspCmd\n"  if($dbg);
#    $Lok=system($conv_phd2dsspCmd);
#    die "ERROR: command=$conv_phd2dsspCmd failed, stopped"
#	if($Lok != 0);
    
    next if(! -e $FileProfRdb);
    $FileProfRdbgz=$FileProfRdb.".gz";
    system("gzip -f $FileProfRdb"); #==0 || die "failed to zip $FileProfRdb, stopped";
    $tmp=$FileProfRdbgz; $tmp=~s/^.*\///;
    ($double)=($tmp=~/^(\S\S).*/);
    $newFileProfRdbgz=$dirRdbOut.$double."/".$tmp;
    rename $FileProfRdbgz, $newFileProfRdbgz;

    if(! $dbg){
	unlink ($BlastForProfOut,$BlastMatOut,$FileSaf,$FileSafHssp,$FileSafHsspFilt,$FileSafFilt);
    }    
}
if(! $dbg && defined $ErrFile && -e $ErrFile){
    unlink $ErrFile;
}
#if(! $dbg){ system("\\rm -rf $work_dir_loc"); }
#============================================================================
sub read_mpearson{
    my $sbr="read_mpearson";
    my ($file,$hr_mpearson)=@_;
    die "$sbr: arguments not defined, stopped"
	if(! defined $file || ! defined $hr_mpearson);
    my ($HomID,$ctLoc,$aliString,$id);
    open(FHINMP,$file) || 
	die "failed to open file=$file, stopped";
    while(<FHINMP>){
	next if(/^\s*$|^\#/);
	if(/^>(\S+)/){ $HomID=$1; $ctLoc=0; undef $aliString; undef $id;}
	elsif(/^(\S+)\t(\S+)/){ 
	    $id=$1; $aliString=$2; $ctLoc++;
	    if($ctLoc==1){ $$hr_mpearson{$HomID}{'query'}=$aliString; }
	    elsif($ctLoc==2){ 
	    die "format of $file not understood, stopped" 
		if($id ne $HomID);
	    $$hr_mpearson{$HomID}{'subject'}=$aliString; 
	}
	    else{ die "format of $file not understood, stopped"; }
	}
    }
    close FHINMP;
    return 1;
}
#=============================================================================
