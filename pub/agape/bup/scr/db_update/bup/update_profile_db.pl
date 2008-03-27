#! /usr/bin/perl -w

($pdbList)=@ARGV;

($dirScr)=($0=~/^(.*\/)/);
$dirScr="./" if(! defined $dirScr);

$configFile=$dirScr."config_uni.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

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

$fileInCore=$pdbList;
$fileInCore=~s/^.*\///; $fileInCore=~s/\..*$//;

$mfasta=$fileInCore.".mfasta";
$cmd=$par{"pdb2fasta_exe"}." ".$pdbList." ".$mfasta;
system($cmd)==0 ||
    die "failed on $cmd, stopped";

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


$cmd=$par{"runBlast_exe"}." ".$mfastaProcd." blast fixdblen";
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

