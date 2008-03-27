#! /usr/bin/perl -w

($list)=@ARGV;

undef %h_core2pdbFile;
$pdbDir="/data/pdb_obsolete/";
opendir(FHDIR,$pdbDir) || die "failed to open dir $pdbDir, stopped";
@l_tmp=readdir FHDIR;
closedir FHDIR;
foreach $it (@l_tmp){ 
    if($it=~/\.pdb$/){ $es=$it; $es=~s/\..*//; $h_core2pdbFile{$es}=$pdbDir.$it; }
}
$pdbDir="/data/pdb/";
opendir(FHDIR,$pdbDir) || die "failed to open dir $pdbDir, stopped";
@l_tmp=readdir FHDIR;
closedir FHDIR;
foreach $it (@l_tmp){ 
    if($it=~/\.pdb$/){ $es=$it; $es=~s/\..*//; $h_core2pdbFile{$es}=$pdbDir.$it; }
}


open(FHIN,$list) || die "failed to open list file=$list, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    next if(/^id/i);
    ($name)=($_=~/^(\S+)/);
    ($coreID)=($name=~/^(\S{4,4})/);
    ($chain)=($name=~/_(\S)$/);
    if(! defined $chain){ $chain=" "; }
    $h_id2coreChain{$name}{"coreID"} =$coreID;
    $h_id2coreChain{$name}{"chain"}  =$chain;
}
close FHIN;
foreach $name (sort keys %h_id2coreChain){
    $coreID=$h_id2coreChain{$name}{"coreID"};
    $chain =$h_id2coreChain{$name}{"chain"};
    $pdbFile=$h_core2pdbFile{$coreID};

    #print "pdbFile=$pdbFile, chain=$chain\n";
    undef %h_resNo2coor;
    &get_PDB_single_chain($pdbFile,$chain,\%h_resNo2coor);
    $seq=""; 
    foreach $resNo (sort {$a <=> $b} keys %h_resNo2coor){
	$seq.=$h_resNo2coor{$resNo}{"res"}; 
    }
    $s_pdbFile="";
    foreach $resNo (sort {$a <=> $b} keys %h_resNo2coor){
	$s_pdbFile.=$h_resNo2coor{$resNo}{"atom"}{"CA"};
    }
    if($chain=~/\S/){ $pdbChainFile=$coreID."_".$chain.".pdb"; }
    else{ $pdbChainFile=$coreID.".pdb"; }
    open(FHOUT,">".$pdbChainFile) ||
	die "failed to open pdbChainFile=$pdbChainFile for writing, stopped";
    print FHOUT "REMARK SEQUENCE: $seq\n";
    print FHOUT $s_pdbFile;
    close FHOUT;
}

	

#========================================================================
sub get_PDB_single_chain{
    my $sbr='get_PDB_single_chain';
    my ($PDBFile,$chainNeed,$hr_resNo2coor)=@_;   #note $PDBFile is a full adress (with PDB directory)
    die "sbr: $sbr arguments not defined, stopped"
	if(! defined $PDBFile || ! defined $chain || ! defined $hr_resNo2coor);
    my ($atom,$ResidueNo,$line,$modelCount,$SeenFlag);
    my ($oneRes,$threeRes,$resCt,$pdbResNum,$atomLoc,
	$inserCode,$numbCode,$chain);
    my (@fields,@Pdb_single_chain_file); 
    my $fh="FH".$sbr;
    my (%h_three2one,%h_resNumbPresent);
    
    %h_three2one= (GLY=>'G',ALA=>'A',VAL=>'V',LEU=>'L',ILE=>'I',PRO=>'P',PHE=>'F',TYR=>'Y',TRP=>'W',SER=>'S',THR=>'T',CYS=>'C',MET=>'M',ASN=>'N',GLN=>'Q',ASP=>'D',GLU=>'E',LYS=>'K',ARG=>'R',HIS=>'H',UNK=>'X');
    die "ERROR $sbr: not all arguments are defined" 
	if(! defined $PDBFile || ! defined $chainNeed || ! defined $hr_resNo2coor);
	    
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
	if($_=~/^SEQRES /){
	    @fields=split(//,$_);
	    if($fields[11] eq $chainNeed){
		substr($_,11,1)=" "; #blank for chain identifier
		push @Pdb_single_chain_file, $_;
	    }
	    next;
	}
	if($_=~/^MODEL /){ 
	    $modelCount++; 
	    if ( $modelCount >1 && $SeenFlag){last;} 
	}
	if($_=~/^TER / && $SeenFlag){ last; }
	if ($_=~/^ATOM/){
	    @fields    =split(//,$_);   
	    $chain     =substr($_,21,1);
	    $atom      =substr($_,12,4); $atomLoc=$atom; $atomLoc=~s/\s//g;
	    $threeRes  =substr($_,17,3);
	    $pdbResNum =substr($_,22,4); $pdbResNum=~s/\s//g;
	    $inserCode  =substr($_,26,1); $inserCode=~s/\s//g;
	    $numbCode   =$pdbResNum.$inserCode;
	    $h_resNumbPresent{$chain}{$numbCode}{$atomLoc}++;	   
	    next if($atom !~ /^\s*CA\s*$/ && $atom !~ /^\s*CB\s*$/); #getting only C alpha and beta
	    next if($chain ne $chainNeed);
	    if ($chain eq $chainNeed){
		if($fields[16] !~ /\s/){
		    if($h_resNumbPresent{$chain}{$numbCode}{$atomLoc} > 1){ next; }
		}
		if($atom =~ /^\s*CA\s*$/){ 
		    $resCt++;
		    $oneRes=$h_three2one{$threeRes};
		    if(! defined $oneRes){
			print "oneRes not defined for threeRes=$threeRes in $PDBFile, assigning X \n";
			$oneRes="X";
		    }
		
		    $SeenFlag=1;
		    $fields[21]=" ";
		    $line=join "", @fields;
		    $$hr_resNo2coor{$resCt}{"atom"}{$atomLoc}=$line;
		    $$hr_resNo2coor{$resCt}{"res"}=$oneRes;
		}
	    }
	}
    }
    close $fh;
    return 1;
}
#=========================================================================
