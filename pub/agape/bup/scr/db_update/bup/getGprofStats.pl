#! /usr/bin/perl -w

($sssa,$fileStatCombOut,$work_dir_loc,$db_dssp_list,$dbg)=@ARGV;
die "ERROR $0: argument fasta not defined, stopped" 
    if(! defined $sssa || ! defined $work_dir_loc || 
       ! defined $db_dssp_list || ! defined $fileStatCombOut);

if(! defined $dbg){ $dbg=0; }

$configFile                   ="/home/dudek/server/pub/agape/scr/agape_config.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

$pathLoc=`pwd`;
$pathLoc=~s/\s//g; 
$pathLoc.="/" if($pathLoc !~ /\/$/);

if($sssa=~/\.list/){
    open(FHIN,$sssa) || die "did not open sssa=$sssa, stopped";
    while(<FHIN>){
        next if(/^\s*$|^\#/);
        s/\s//g;
	if($_!~/.*\//){ $_=$pathLoc.$_; }
        $h_sssasIn{$_}=1;
    }
    close FHIN;
}else{ 
    if($sssa !~/.*\//){ $sssa=$pathLoc.$sssa; }
    $h_sssasIn{$sssa}=1; 
}

if($fileStatCombOut !~/.*\//){ $fileStatCombOut=$pathLoc.$fileStatCombOut; }


#$par{'work_dir'}.="/" if( $par{'work_dir'} !~ /\/$/ );

#$work_dir_loc=$par{"work_dir"}."work_GProfStat"."-".$$."/";
#system("\\mkdir $work_dir_loc")==0 ||
#    die "failed to mkdir=$work_dir_loc, stopped";
chdir ($work_dir_loc) || 
	die "ERROR: failed to chdir to work_dir_loc=$work_dir_loc, stopped";

$tmp=$sssa; $tmp=~s/^\s*$|\..*$//g;
$LogFile =$tmp.".log";
$ErrFile =$tmp.".err";
if(! $dbg){ open(STDERR,">".$ErrFile); 
	    open(STDOUT,">".$LogFile); }

open(FHSTATCOUT,">".$fileStatCombOut) ||
    die "failed to open fileStatCombOut for writing, stopped";

foreach $fileSSSA (sort keys %h_sssasIn){
    $QueryName       =$fileSSSA;
    $QueryName       =~s/^.*\/|\..*$//g;
    $QueryID=$QueryName;
    print "QueryName: $QueryName\n";
    
    $fileStatOut=$QueryID.".distn-dat";
    $sssaInLoc=$fileSSSA; $sssaInLoc=~s/^.*\///; 
    system("cp $fileSSSA $sssaInLoc")==0 ||
	die "failed to cp $fileSSSA to $sssaInLoc, stopped";
    
    $FileMaxhomFrwdHssp   =$work_dir_loc.$QueryID.".hssp-frwd";
    $FileMaxhomFrwdStrip  =$work_dir_loc.$QueryID.".strip-frwd";
    $FileParsedFrwdStrip  =$work_dir_loc.$QueryID.".frwd-parsed";

    $Maxhom_frwdCmd="$par{maxhom_frwd_exe} $sssaInLoc $par{db_dssp_list} $FileMaxhomFrwdHssp $FileMaxhomFrwdStrip $work_dir_loc 0 11 1 $main::par{maxhom_binary} $main::par{maxhom_default} $dbg";
    print "executing:\n$Maxhom_frwdCmd\n"  if($dbg);
    $Lok=system($Maxhom_frwdCmd);
    #print "Lok: $Lok\n";
    die "ERROR: command=$Maxhom_frwdCmd failed, stopped"
	if($Lok != 0);
    
    $parseStripFrwdCmd="$par{parseStripFrwd_exe} $FileMaxhomFrwdStrip $par{db_relat} $par{db_dssp_list} $fileStatOut";
    print "executing:\n$parseStripFrwdCmd\n"  if($dbg);
    $Lok=system($parseStripFrwdCmd);
    die "ERROR: command=$parseStripFrwdCmd failed, stopped"
	if($Lok != 0);

    open(FHSTATLOCIN,$fileStatOut) ||
	die "failed to open fileStatOut=$fileStatOut, stopped";
    while(<FHSTATLOCIN>){
	next if(/^\s*$|^\#/);
	print FHSTATCOUT $_;
    }
    close FHSTATLOCIN;

    unlink ($FileMaxhomFrwdHssp,$FileMaxhomFrwdStrip);
    if(! $dbg){
	unlink ($sssaInLoc,$FileMaxhomFrwdHssp,$FileMaxhomFrwdStrip,$FileParsedFrwdStrip);
    }    
    
    if(! $dbg && defined $ErrFile && -e $ErrFile){
	unlink $ErrFile;
    }
    #if(! $dbg){ system("\\rm -rf $work_dir_loc"); }
}
close FHSTATCOUT;

#============================================================================
sub read_mpearson{
    my $sbr="read_mpearson";
    my ($file,$hr_mpearson)=@_;
    die "$sbr: arguments not defined, stopped"
	if(! defined $file || ! defined $hr_mpearson);
    my ($HomID,$ctLoc,$aliStrin,$id);
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
