#! /usr/bin/perl -w

($idListFile,@l_args)=@ARGV;

($dirScr)=($0=~/^(.*\/)/);
$dirScr="./" if(! defined $dirScr);

$mfasta=0;
foreach $arg (@l_args){
    if($arg =~/dirOut=(\S+)/i)  { $dirOut=$1; }
    elsif($arg =~ /mfasta=(\S+)/i)  { $mfasta=$1; }
}


if(defined $dirOut){
    $dirOut.='/' if($dirOut !~ /\/$/);
}else{ $dirOut="./"; }

$configFile=$dirScr."config_uni.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";

die "par{lr_pdb_dirs} not defined, stopped"
    if(! defined $par{"lr_pdb_dirs"});
@l_pdb_dirs=@{ $par{"lr_pdb_dirs"} };


open(FH,$idListFile) || die "failed to open $idListFile, stopped";
while(<FH>){
    next if(/^\s*$|^\#/);
    next if(/^id\t/);
    ($id)=($_=~/^(\S+)/); 
    $protein=substr($id,0,4);
    $foundFlag=0;
    foreach $dir (@l_pdb_dirs){
	$file=$dir.$protein.".pdb";
	if(-e $file){
	    $h_list{$id}=$file;
	    $foundFlag=1;
	    last;
	}
    }
    if(! $foundFlag){
	die "ERROR: pdb file for $protein not found, stopped";
    }
}
close FH;
if($mfasta ne "0"){
    open(FHOUT,">".$mfasta) ||
	die "failed to open mfasta=$mfasta, stopped";
}
foreach $id (sort keys %h_list){
    $pdbFile=$h_list{$id};
    if(length($id) > 4){ 
	die "format of id=$id not understood, stopped" if(length($id) != 6);
	($chain)=($id=~/^\S{5,5}(\S)/);
    }else{ $chain=" "; }

    ($Lok,$msg,$seq)=&get_PDB_chain_fasta($pdbFile,$chain);
    die "ERROR $msg, stopped" if(! $Lok);
    die "ERROR: no sequence found for $id, stopped"
	if(! defined $seq || $seq !~ /\S/);

    $fileOut=$dirOut.$id.".f";
    
    if($mfasta eq "0"){
	open(FHOUT,">".$fileOut) || 
	    die "ERROR failed to open fileOut=$fileOut, stopped";
    }
    print FHOUT ">".$id."\n";
    print FHOUT $seq."\n";
}


#========================================================================
sub get_PDB_chain_fasta{
    my $sbr='get_PDB_chain_fasta';
    my ($PDBFile,$chainNeed)=@_;   #note $PDBFile is a full adress (with PDB directory)
    die "sbr: $sbr arguments not defined, stopped"
	if(! defined $PDBFile || ! defined $chainNeed);
    my ($atom,$ResidueNo,$line,$modelCount,$SeenFlag);
    my ($oneRes,$threeRes,$resCt,$atomTmp,$seq,$pdbResNum,$atomLoc,
	$inserCode,$numbCode,$chain);
    my (@fields,@Pdb_single_chain_file); 
    my $fh="FH".$sbr;
    my (%h_three2one,%h_resNumbPresent);
    
    %h_three2one= (GLY=>'G',ALA=>'A',VAL=>'V',LEU=>'L',ILE=>'I',PRO=>'P',PHE=>'F',TYR=>'Y',TRP=>'W',SER=>'S',THR=>'T',CYS=>'C',MET=>'M',ASN=>'N',GLN=>'Q',ASP=>'D',GLU=>'E',LYS=>'K',ARG=>'R',HIS=>'H',UNK=>'X',HYP=>'X',ACE=>'X',PCA=>'X');
    die "ERROR $sbr: not all arguments are defined" 
	if(! defined $PDBFile);
    
    if($PDBFile=~/\.gz$/){
	$cmd="gunzip -c $PDBFile";
	open($fh,"$cmd |") ||
	    die "ERROR failed to open $cmd, stopped";
    }else{
	open($fh,$PDBFile) ||
	    die "ERROR failed to open PDBFile=$PDBFile, stopped";
    }
    
    $modelCount=0; $SeenFlag=0; $resCt=0;
    while (<$fh>){
	if($_=~/^MODEL /){ 
	    $modelCount++; 
	    if ( $modelCount >1 && $SeenFlag){last;} 
	}
	if($_=~/^TER / && $SeenFlag){ last; }
	if ($_=~/^ATOM/){
	    @fields     =split(//,$_);   
	    $atom       =substr($_,12,4); $atomLoc=$atom; $atomLoc=~s/\s//g;
	    $threeRes   =substr($_,17,3);
	    $chain      =substr($_,21,1);
	    $pdbResNum  =substr($_,22,4); $pdbResNum=~s/\s//g;
	    $inserCode  =substr($_,26,1); $inserCode=~s/\s//g;
	    $numbCode   =$pdbResNum.$inserCode;
	    $h_resNumbPresent{$chain}{$numbCode}{$atomLoc}++;
	    next if($atom !~ /^\s*CA\s*$/ ); #getting only C alpha
	    next if($chain ne $chainNeed);
	    if ($chain eq $chainNeed){		
		if($fields[16] !~ /\s/){
		    if($h_resNumbPresent{$chain}{$numbCode}{$atomLoc} > 1){ next; }
		}
		$h_resNumbPresent{$pdbResNum}{$atomLoc}++;
		$resCt++;
		$oneRes=$h_three2one{$threeRes};
		if(! defined $oneRes){
		    print "oneRes not defined for threeRes=$threeRes in $PDBFile, assigning X \n";
		    $oneRes="X";
		}
	   
		$SeenFlag=1;
		$fields[21]=" ";
		$line=join "", @fields;
		$atomTmp=$atom; $atomTmp=~s/\s//g;
		$seq.=$oneRes;
	    }
	}
    }
    close $fh;
    return (1,"ok",$seq);
}
#=========================================================================
