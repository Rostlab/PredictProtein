#! /usr/bin/perl -w

($pdbList,@l_args)=@ARGV;

($dirScr)=($0=~/^(.*\/)/);
$dirScr="./" if(! defined $dirScr);

$configFile=$dirScr."config_uni.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

$dbg=0;
foreach $arg (@l_args){
    if($arg =~ /^mfasta$/i)             { $ismfasta=1; }
    elsif($arg  =~ /^blast$/i)           { $blastType="blast"; }
    elsif($arg  =~ /^psi$|^psiblast$/i)  { $blastType="psi"; }
    elsif($arg  =~ /^fixdblen$/i)        { $dbSizeArg="fixdblen"; }
    elsif($arg  =~ /^psidblen$/i)        { $dbSizeArg="psidblen"; }
    elsif($arg  =~ /^dbg$/i)        { $dbg=1; }
}

if(! defined $ismfasta){ $ismfasta=0; }
if(! defined $blastType) { $blastType="blast"; }


$fileInCore=$pdbList;
$fileInCore=~s/^.*\///; $fileInCore=~s/\..*$//;

$pathLoc=`pwd`;
$pathLoc=~s/\s//g; 
$pathLoc.="/" if($pathLoc !~ /\/$/);

if($pdbList !~ /\//){ $pdbList=$pathLoc.$pdbList; }

if(defined $par{'work_dir'}){
    $par{'work_dir'}.="/" if( $par{'work_dir'} !~ /\/$/ );
    $work_dir_loc=$par{"work_dir"}."work_uni"."-".$$."/";
}else{ $work_dir_loc="work_uni"."-".$$."/"; }

system("\\mkdir $work_dir_loc")==0 ||
    die "failed to mkdir=$work_dir_loc, stopped";
chdir ($work_dir_loc) || 
	die "ERROR: failed to chdir to work_dir_loc=$work_dir_loc, stopped";


if(! $ismfasta){
#get h_coreID2pdbFile
    undef %h_coreID2pdbFile;
    open(FHIN,$pdbList) || 
	die "failed to open pdbList=$pdbList, stopped";
    while(<FHIN>){
	next if(/^\s*$|^\#/);
	s/\s//g;
	$coreID=$pdbFile=$_;
	$coreID=~s/^.*\/|\..*$//g;
	$h_coreID2pdbFile{$coreID}=$pdbFile;
    }
    close FHIN;
 
    $mfasta=$fileInCore.".mfasta";
    $cmd=$par{"pdb2fasta_exe"}." ".$pdbList." ".$mfasta;
    system($cmd)==0 ||
	die "failed on $cmd, stopped";
}else{ $mfasta=$pdbList; }

$mfastaProcd=$mfasta."-procd";
$cmd=$par{"procMfasta_exe"}." ".$mfasta." fileOut=$mfastaProcd minlen=".$par{"minlen"}." unk=".$par{"maxUnkFrac"};
system($cmd)==0 ||
    die "failed on $cmd, stopped";

$fileLengths=$fileInCore.".length-dat";
$cmd=$par{"mfasta2lengths_exe"}." ".$mfastaProcd." ".$fileLengths;
system($cmd)==0 ||
    die "failed on $cmd, stopped";


undef %h_pdbIds;
open(FHIN,$fileLengths) || 
    die "failed to open fileLengths=$fileLengths, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    ($id)=/^(\S+)/;
    $h_pdbIds{$id}=1;
}
close FHIN;

$fileIds=$fileInCore.".ids-procd";
open(FHOUT,">".$fileIds) || 
    die "failed to open fileIds=$fileIds for wrt, stopped";
foreach $id (sort keys %h_pdbIds){ print FHOUT $id."\n"; }
close FHOUT;


$blastArgs=$blastType; $blastArgs.=" $dbSizeArg" if(defined $dbSizeArg);
$cmd=$par{"runBlast_exe"}." ".$mfastaProcd." ".$blastArgs;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

$blastM9List=$fileInCore."-blast-m9.list";
open(FHOUT,">".$blastM9List) || 
    die "failed to open blastM9List=$blastM9List for wrt, stopped";
foreach $id (sort keys %h_pdbIds){ print FHOUT $id.".blastm9.gz\n"; }
close FHOUT;

$minHsspDist=0;
$cmd=$par{"blastm9ToUniRdb_exe"}." ".$blastM9List." ".$minHsspDist;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

$blastRdbList=$fileInCore."-blast-rdb.list";
open(FHOUT,">".$blastRdbList) || 
    die "failed to open blastRdbList=$blastRdbList for wrt, stopped";
foreach $id (sort keys %h_pdbIds){ print FHOUT $id.".rdbBlast.gz\n"; }
close FHOUT;

$fileMultiRdb=$fileInCore.".mrdb";
$cmd=$par{"concRdbs_exe"}." ".$blastRdbList." ".$fileMultiRdb;
system($cmd)==0 ||
    die "failed on $cmd, stopped";


#get files with info
$fileExcludeDat=$fileInCore.".2exclude-dat";
$cmd=$par{"pdbid2exclude_exe"}." ".$fileIds." ".$fileExcludeDat;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

$fileResolutionDat=$fileInCore.".resolution-dat";
$cmd=$par{"pdbid2resolution_exe"}." ".$fileIds." ".$fileResolutionDat;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

$fileTypeDat=$fileInCore.".type-dat";
$cmd=$par{"pdbid2type_exe"}." ".$fileIds." ".$fileTypeDat;
system($cmd)==0 ||
    die "failed on $cmd, stopped";


$cmd=$par{"mrdb2unique_exe"}." ".$fileMultiRdb." ids=".$fileIds." types=".$fileTypeDat." resolution=".$fileResolutionDat." lengths=".$fileLengths;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

if(! $dbg){
    system("\\rm -fr $work_dir_loc")==0 ||
	die "failed to rm $work_dir_loc, stopped"; 
}
