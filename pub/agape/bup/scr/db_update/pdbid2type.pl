#! /usr/bin/perl -w

($idListFile,$fileOut)=@ARGV;

($dirScr)=($0=~/^(.*\/)/);
$dirScr="./" if(! defined $dirScr);

$configFile=$dirScr."config_uni.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

die "pdb_dirs not defined, stopped" 
    if(! defined $par{"lr_pdb_dirs"});
@l_pdb_dirs=@{ $par{"lr_pdb_dirs"} };

open(FH,$idListFile) || die "failed to open $idListFile, stopped";

open(FH,$idListFile) || die "failed to open $idListFile, stopped";
while(<FH>){
    next if(/^\s*$|^\#/);
    s/\s//g;
    $protein=$_; $protein=substr($protein,0,4);
    $foundFlag=0;
    foreach $dir (@l_pdb_dirs){
	$file=$dir.$protein.".pdb";
	if(-e $file){
	    $h_list{$_}=$file;
	    $foundFlag=1;
	    last;
	}
    }
    if(! $foundFlag){
	die "ERROR: pdb file for $protein not found, stopped";
    }
}
close FH;

foreach $id (sort keys %h_list){
    $pdbFile=$h_list{$id};
    ($Lok,$msg,$type)=&get_PDB_type($pdbFile);
    die "ERROR $msg, stopped" if(! $Lok);
    $h_res{$id}=$type;
}
if(! defined $fileOut){
    $fileOut=$idListFile; $fileOut=~s/^.*\/|\..*$//g;
    $fileOut.=".types";
}
open(FHOUT,">".$fileOut) || 
    die "ERROR failed to open fileOut=$fileOut, stopped";
foreach $id (sort keys %h_res){
    print FHOUT $id."\t".$h_res{$id}."\n";
}
close FHOUT;



#===============================================================================
sub get_PDB_type{
    local $sbr='get_PDB_type';
    my $PDBFile=$_[0];
    my (@tmp,$type,$found);
    open(FHLOC,$PDBFile) ||
	return(0,"ERROR $sbr: did not open file=$PDBFile");
    $found=0;
    while(<FHLOC>){
	last if(/^ATOM/);
	if($_!~/^EXPDTA/){ next; }
	else{
	    $found=1;
	    s/\s*$//;
	    ($type)=/EXPDTA\s*(.*)/;
	    $type=~s/\s*$//;
	    $type=~s/^(.{1,30}).*\s*/$1/;
	    die "type not found in: $type, stopped"
		if(! defined $type);
	    last;
	}
    }
    close FHLOC;
    if(! $found){
	print "WARN: field EXPDTA not found in $PDBFile, assigning UNK\n";
	$type="UNK";
    }else{
	if($type=~/X-RAY/){ $type="X-RAY"; }
	elsif($type=~/NMR/){ $type="NMR"; }
	else{ 
	    print "unknown type in $PDBFile:$_\n"; 
	}
    }
    return(1,'ok',$type);
}
#===============================================================================
