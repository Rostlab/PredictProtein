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
    $error=0;
    ($Lok,$msg,$error,$type)=&get_PDB_errors($pdbFile);
    die "ERROR $msg, stopped" if(! $Lok);
    $h_res{$id}=$type if($error);
}
if(! defined $fileOut){
    $fileOut=$idListFile; $fileOut=~s/^.*\/|\..*$//g;
    $fileOut.=".errors";
}
open(FHOUT,">".$fileOut) || 
    die "ERROR failed to open fileOut=$fileOut, stopped";
foreach $id (sort keys %h_res){
    print FHOUT $id."\t".$h_res{$id}."\n";
}
close FHOUT;



#===============================================================================
sub get_PDB_errors{
    local $sbr='get_PDB_errors';
    my $PDBFile=$_[0];
    my (@tmp,$type,$found);
    open(FHLOC,$PDBFile) ||
	return(0,"ERROR $sbr: did not open file=$PDBFile");
    $found=0;
    while(<FHLOC>){
	last if(/^ATOM/);
	if($_=~/^CAVEAT/){ $found=1; $type=$_; $type=~s/\n$//;}
	last if($found);
    }
    close FHLOC;
    return(1,'ok',$found,$type);
}
#===============================================================================
