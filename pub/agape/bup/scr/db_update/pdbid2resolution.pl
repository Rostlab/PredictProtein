#! /usr/bin/perl -w

($idListFile,$fileOut)=@ARGV;

($dirScr)=($0=~/^(.*\/)/);
$dirScr="./" if(! defined $dirScr);

$configFile=$dirScr."config_uni.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

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
    ($Lok,$msg,$res)=&get_PDB_resolution($pdbFile);
    die "ERROR $msg, stopped" if(! $Lok);
    $h_res{$id}=$res;
    #print $id."\t".$h_res{$id}."\n";
}
if(! defined $fileOut){
    $fileOut=$idListFile; $fileOut=~s/^.*\/|\..*$//g;
    $fileOut.=".resolutions";
}
open(FHOUT,">".$fileOut) || 
    die "ERROR failed to open fileOut=$fileOut, stopped";
foreach $id (sort {$h_res{$a} <=> $h_res{$b} } keys %h_res){
    print FHOUT $id."\t".$h_res{$id}."\n";
}
close FHOUT;



#===============================================================================
sub get_PDB_resolution{
    local $sbr='get_PDB_resolution';
    my $PDBFile=$_[0];
    my (@tmp,$Resolution);
    open(FHLOC,$PDBFile) ||
	return(0,"ERROR $sbr: did not open file=$PDBFile");
    while(<FHLOC>){
	last if(/^ATOM/);
	s/\s*$//;
	if(/^REMARK\s*2\s*RESOLUTION\.\s*(.+)/){
	    $Resolution=$1;
	    @tmp=split(/\s+/,$Resolution);
	    if($tmp[0]=~/[0-9\.]+/){ $Resolution=$tmp[0]; 
				     $Resolution=~s/ANGS.*$//;}
	    elsif( ($tmp[0] eq 'NOT') && ($tmp[1] =~ 'APPLICABLE') ){
		$Resolution=$par{'NMR_resolution'};
	    }
	    else{
		print "unexpected RESOLUTION format in line:\n$_\n";
		$Resolution=$par{'unk_resolution'};
	    }
	    last;
	}
    }
    close FHLOC;
    if(! defined $Resolution){ 
	print "Resolution for $PDBFile not defined, assigning $par{unk_resolution}\n";
	$Resolution= $par{'unk_resolution'};
    }
    
    return(1,'ok',$Resolution);
}
#===============================================================================
