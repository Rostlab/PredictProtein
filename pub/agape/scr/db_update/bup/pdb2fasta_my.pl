#! /usr/bin/perl -w

($pdbList,$fileOut)=@ARGV;


open(FHIN,$pdbList) || die "failed to open list file=$pdbList, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    s/\s//g;
    $h_filesIn{$_}=1;
}
close FHIN;

if(! defined $fileOut){
    $fileOut=$pdbList; $fileOut=~s/^.*\///; $fileOut="mfasta-".$fileOut;
}
open(FHOUT,">".$fileOut) || die "failed to open fileOut=$fileOut for output, stopped";
foreach $pdbFile (sort keys %h_filesIn){
    $coreID=$pdbFile; $coreID=~s/^.*\/|\..*$//g;
    undef %h_chain2seq;
    &get_PDB_chains($pdbFile,\%h_chain2seq);
    
    undef %h_chain2seqUni;
    foreach $chain (sort keys %h_chain2seq){
	$seq=$h_chain2seq{$chain};
	$flagIn=0;
	foreach $chainIn (sort keys %h_chain2seqUni){
	    $seqIn=$h_chain2seqUni{$chainIn};
	    if($seq eq $seqIn){ $flagIn=1; last; }
	}
	$h_chain2seqUni{$chain}=$seq if(! $flagIn);
    }
    foreach $chain (sort keys %h_chain2seqUni){
	if($chain=~/\S/){ $id=$coreID."_".$chain; }
	else{ $id=$coreID; }
	print FHOUT ">$id\n";
	print FHOUT "$h_chain2seqUni{$chain}\n";
    }
}
close FHOUT;

#========================================================================
sub get_PDB_chains{
    my $sbr='get_PDB_chains';
    my ($PDBFile,$hr_chain2seq)=@_;   #note $PDBFile is a full adress (with PDB directory)
    die "sbr: $sbr arguments not defined, stopped"
	if(! defined $PDBFile || ! defined $hr_chain2seq);
    my ($atom,$ResidueNo,$line,$modelCount,$SeenFlag);
    my ($oneRes,$threeRes,$resCt,$atomTmp,$pdbResNum,$atomLoc,
	$inserCode,$numbCode,$chain);
    my (@fields,@Pdb_single_chain_file); 
    my $fh="FH".$sbr;
    my (%h_three2one,%h_resNumbPresent,%h_resNumbAtomPresent);
          
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
	if ($_=~/^ATOM/){
	    @fields=split(//,$_);   
	    $atom       =substr($_,12,4); $atomLoc=$atom; $atomLoc=~s/\s//g;
	    $threeRes   =substr($_,17,3);
	    $chain      =substr($_,21,1);
	    $pdbResNum  =substr($_,22,4); $pdbResNum=~s/\s//g;
	    $inserCode  =substr($_,26,1); $inserCode=~s/\s//g;
	    $numbCode   =$pdbResNum.$inserCode;
	    $h_resNumbAtomPresent{$chain}{$numbCode}{$atomLoc}++;

	    next if($atomLoc ne "CA" && $atomLoc ne "C" && $atomLoc ne "N" && $atomLoc ne "O"); #getting only C alpha and beta

	    $h_resNumbPresent{$chain}{$numbCode}++;
	    if($fields[16] !~ /\s/){
		#discard alternative locations, take only the first one
		if($h_resNumbAtomPresent{$chain}{$numbCode}{$atomLoc} > 1){ next; }
	    }
	    #print $_;
	    #print "h_resNumbPresent{$chain}{$numbCode} $h_resNumbPresent{$chain}{$numbCode}\n";
	    if($h_resNumbPresent{$chain}{$numbCode} ==1){ 
		$resCt++;
		$oneRes=$h_three2one{$threeRes};
		if(! defined $oneRes){
		    print "oneRes not defined for threeRes=$threeRes in $PDBFile, assigning X \n";
		    $oneRes="X";
		}
		$$hr_chain2seq{$chain}.=$oneRes;
	    } 
	    $SeenFlag=1;
	    $fields[21]=" ";
	    $line=join "", @fields;
	    $atomTmp=$atom; $atomTmp=~s/\s//g;

	}
    }

    close $fh;
    return 1;
}
#=========================================================================
