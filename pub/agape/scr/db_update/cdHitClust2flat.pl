#! /usr/bin/perl -w

($cdHitClstr)=@ARGV;

my ($numb,$status,$len);
open(FHIN,$cdHitClstr) ||
    die "ERROR: failed to open cdHitClstr=$cdHitClstr, stopped";
while(<FHIN>){
    next if(/^\s*$/);
    #print $_;
    if(/^>Cluster\s+(\S+)/){ 
	$clusterCt=$1; 
	die "ERROR: cluster=$clusterCt already defined, stopped"
	    if(defined $h_clusters{$clusterCt});
	next;
    }
    ($numb,$len,$id,$status)=($_=~/^(\d+)\s+(\d+)aa\,\s+>(\S+)\s+(\S+).*\s*/);
    #print "numb, len, id, status: $numb, $len, $id, $status\n";
    $id=~s/\.*$//; 
    $h_clusters{$clusterCt}{$id}=1;
}
close FHIN;

$tmp=$cdHitClstr; $tmp=~s/^.*\///; 
$fileOutClust="Out-flat-".$tmp;
open(FHOUTCLUST,">".$fileOutClust) ||
    die "failed to open fileOutClust=$fileOutClust for output, stopped";


foreach $clusterCt (keys %h_clusters){
    @l_ids=sort keys %{ $h_clusters{$clusterCt} };
    $tmp=join ",", @l_ids;
    print FHOUTCLUST $tmp."\n";
}
close FHOUTCLUST;    
