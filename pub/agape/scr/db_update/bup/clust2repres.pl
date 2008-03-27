#! /usr/bin/perl -w

($flatClustFile,$rmsdFile,$lenFile)=@ARGV;

open(FHIN,$rmsdFile) ||
    die "ERROR: failed to open rmsdFile=$rmsdFile, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    s/\s*$//;
    ($id,$rmsd)=split(/\s+/,$_);
    $h_id2rmsd{$id}=$rmsd;
}
close FHIN;

open(FHIN,$lenFile) ||
    die "ERROR: failed to open lenFile=$lenFile, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    s/\s*$//;
    ($id,$len)=split(/\s+/,$_);
    $h_id2len{$id}=$len;
}
close FHIN;

my ($numb,$status);
$clusterCt=0;
open(FHIN,$flatClustFile) ||
    die "ERROR: failed to open flatClustFile=$flatClustFile, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    $clusterCt++;
    $_=~s/\s*$//;
    @l_ids=split(/\,/,$_);
    
    foreach $id (@l_ids){
	$rmsd=$h_id2rmsd{$id};
	die "ERROR: rmsd for id=$id not defined, stopped"
	    if(! defined $rmsd);
	$len=$h_id2len{$id};
	die "ERROR: len for id=$id not defined, stopped"
	    if(! defined $len);

        $h_clusters{$clusterCt}{$id}{"rmsd"}  =$rmsd;
	$h_clusters{$clusterCt}{$id}{"len"}   =$len;
    }
}
close FHIN;

$tmp=$flatClustFile; $tmp=~s/^.*\///; 
$fileOutClust="Out-clust-".$tmp;
$fileOutList="Out-list-".$tmp;
open(FHOUTCLUST,">".$fileOutClust) ||
    die "failed to open fileOutClust=$fileOutClust for output, stopped";
open(FHOUTLIST,">".$fileOutList) ||
    die "failed to open fileOutList=$fileOutList for output, stopped";

#choose representative of good length and rmsd
foreach $clusterCt (keys %h_clusters){
    print "\n------ cluster $clusterCt -----------\n";
    @l_ids=(); @l_idsLoc=();
    @l_ids=sort 
    {  
	$h_clusters{$clusterCt}{$b}{"len"} <=> $h_clusters{$clusterCt}{$a}{"len"} or 
	$h_clusters{$clusterCt}{$a}{"rmsd"} <=> $h_clusters{$clusterCt}{$b}{"rmsd"}
       or $a cmp $b
    } 
    keys %{ $h_clusters{$clusterCt} };

    foreach $id (@l_ids){
	$rmsd=$h_clusters{$clusterCt}{$id}{"rmsd"};
	$len =$h_clusters{$clusterCt}{$id}{"len"};
	print $id."\t".$rmsd."\t".$len."\n";
    }

    $maxLen  =$h_clusters{$clusterCt}{$l_ids[0]}{"len"};
    $allowLen=int (0.9 * $maxLen);
    $idR     =$l_ids[0];
    $rmsdR   =$h_clusters{$clusterCt}{$idR}{"rmsd"};
    $lenR    =$h_clusters{$clusterCt}{$idR}{"len"};

    if($rmsdR > 2.0){
	print "looking for shorter representative with better rmsd\n";
	@l_idsLoc=();
	foreach $id (@l_ids){ 
	    $len=$h_clusters{$clusterCt}{$id}{"len"}; 
	    push @l_idsLoc, $id if($len >=$allowLen);
	}
	@l_idsLoc=sort { $h_clusters{$clusterCt}{$a}{"rmsd"} <=> $h_clusters{$clusterCt}{$b}{"rmsd"} } @l_idsLoc;
	$idR=$l_idsLoc[0];
	$rmsdR=$h_clusters{$clusterCt}{$idR}{"rmsd"};
	$lenR =$h_clusters{$clusterCt}{$idR}{"len"};
    }
    #resort alphabetically for output
    @l_ids=sort @l_ids;
    $tmp=join ",", @l_ids;
    $lineOut=$idR."\t".$tmp."\n";
    print FHOUTCLUST $lineOut;
    print "representative: ".$idR."\t".$rmsdR."\t".$lenR."\n";
    print FHOUTLIST $idR."\n";
}
	
close FHOUTCLUST; close FHOUTLIST;
    
