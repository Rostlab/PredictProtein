#! /usr/bin/perl -w

#only one field and threshold can be set
#only family clustering is probably working fine
($rdbFileIn,@l_args)=@ARGV;

foreach (@l_args){
    if(/resolution=(\S+)/)       { $fileResolution  =$1; }
    elsif(/lengths=(\S+)/)       { $fileLengths     =$1; }
    elsif(/ids=(\S+)/)           { $fileIds         =$1; }
    elsif(/types=(\S+)/)         { $fileTypes       =$1; }
    else{ die "argument $_ not understood, stopped"; }
}

$clust_field="dist";
$threshold  =0;
$minLength  =30;

if(! defined $fileIds){
    die "ERROR: argument ids not defined, stopped"
	if(! defined $fileIds);
}

open(FHIN,$fileIds) || 
    die "failed to open fileIds=$fileIds, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s*$//;
    $id=$_;
    $h_ids{$id}=1;
}    
close FHIN;

if(defined $fileResolution){
    open(FHIN,$fileResolution) || 
	die "failed to open fileResolution=$fileResolution, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s*$//;
	($id,$rmsd)=split(/\t/,$_);
	$h_info{$id}{"rmsd"}= $rmsd;
    }    
    close FHIN;
    foreach $id (keys %h_ids){ 
	if(! defined $h_info{$id}{"rmsd"}){
	    print "resolution for $id not found, setting equal to 9999\n";
	    $h_info{$id}{"rmsd"}=9999;
	}
    }
}else{
    print "INFO: Resolution file not found, not considered\n"; 
    foreach $id (keys %h_ids){ $h_info{$id}{"rmsd"}=1;}
}

if(defined $fileLengths){
    open(FHIN,$fileLengths) || 
	die "failed to open fileLengths=$fileLengths, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s*$//;
	($id,$length)=split(/\t/,$_);
	if($length < $minLength){
	    print "excluding $id, length=$length is too short\n";
	    delete $h_ids{$id};
	    next;
	}
	$h_info{$id}{"length"}= $length;
    }    
    close FHIN;
    foreach $id (keys %h_ids){ 
	if(! defined $h_info{$id}{"length"}){
	    print "length for $id not found, setting equal to 1\n";
	    $h_info{$id}{"length"}=1;
	}
    }
}else{
    print "INFO: length file not found, not considered\n"; 
    foreach $id (keys %h_ids){ $h_info{$id}{"length"}=1;}
}
if(defined $fileTypes){
    open(FHIN,$fileTypes) || 
	die "failed to open fileTypes=$fileTypes, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s*$//;
	($id,$type)=split(/\t/,$_);
	if($type eq "X-RAY"){ $typeVal=0; }
	elsif($type eq "NMR"){ $typeVal=1; }
	else{ $typeVal=1; }
	$h_info{$id}{"typeVal"}= $typeVal;
	$h_info{$id}{"type"}= $type;
    }    
    close FHIN;
    foreach $id (keys %h_ids){ 
	if(! defined $h_info{$id}{"typeVal"}){
	    print "typeVal for $id not found, setting equal to 1 (lowest priority)\n";
	    $h_info{$id}{"typeVal"}=1;
	    $h_info{$id}{"type"}="UNK";
	}
    }
}else{
    print "INFO: type file not found, not considered\n"; 
    foreach $id (keys %h_ids){ $h_info{$id}{"typeVal"}=1;}
    foreach $id (keys %h_ids){ $h_info{$id}{"type"}="ANY"; }
}



#read rdb file into h_data
($rh_data)=&read_relationship_hash($rdbFileIn,$clust_field,$threshold,\%h_ids);
$tmp=$rdbFileIn;
$tmp=~s/^.*\/|\..*$//g;
$FileUniqueList=$tmp."-unique.list";
$FileClusters=$tmp.".clusters_cl";
$FileClustersScores=$tmp.".clusters_scores_cl";

srand (time ^ $$ ^ unpack "%32L*", `ps axww | gzip`); #seeding rand function

#now make sure h_data has entry for every pair
foreach $id1 (keys %{ $rh_data } ){
    foreach $id2 (keys %{ $rh_data -> {$id1} } ){
	$val=$rh_data -> {$id1} -> {$id2};
	#print $id1."\t$id2\t".$val."\n";
	if( ! exists $rh_data -> {$id2} -> {$id1} ){
	    $$rh_data{$id2}{$id1}=$val;  
	}
	#print $id2."\t$id1\t".$$rh_data{$id2}{$id1}."\n------\n\n";
    }
}

#foreach $id1 (keys %{ $rh_data } ){
 #   print "id0: $id1\n" if($id1 !~/^d\w{6,6}/);
#}
#exit;
#----------------------------------------------------------

#($rh_clusters)=&cluster_complete_linkage($rh_data);
#($rh_clusters)=&cluster_single_linkage($rh_data);
($rh_clusters)=&cluster_family_size_order($rh_data,"increasing");
%h_clusters=%{ $rh_clusters };
$FileUniqueListHtml=$FileUniqueList.".html";
open(FHLIST,">".$FileUniqueList) || 
    die "failed to open FileUniqueList=$FileUniqueList for writing, stopped";
print FHLIST "id\trmsd\tlength\ttype\n";
open(FHLISTHTML,">".$FileUniqueListHtml) || 
    die "failed to open FileUniqueList=$FileUniqueList for writing, stopped";

print FHLISTHTML "<html>\n";
print FHLISTHTML "<TABLE BORDER='1'><TR><TD>id</TD><TD>rmsd</TD><TD>length</TD><TD>type</TD>\n";

open(FHCLUST,">".$FileClusters) || 
    die "failed to open FileClusters=$FileClusters for writing, stopped";
open(FHCLUSTS,">".$FileClustersScores) || 
    die "failed to open FileClustersScores=$FileClustersScores for writing, stopped";
foreach $id1 (sort keys %h_clusters ){
    $length =$h_info{$id1}{"length"};
    $rmsd   =$h_info{$id1}{"rmsd"};
    $h_outputOrder{$id1}{"length"} =$length;
    $h_outputOrder{$id1}{"rmsd"}   =$rmsd;
}
foreach $id1 (sort { 
    $h_outputOrder{$a}{"rmsd"} <=> $h_outputOrder{$b}{"rmsd"} 
    or $h_outputOrder{$b}{"length"} <=> $h_outputOrder{$a}{"length"}
    or $a cmp $b } keys %h_outputOrder ){
    
    $rmsd=$h_info{$id1}{"rmsd"};
    if($rmsd eq "9.999" || $rmsd >=90){ $rmsd="NA"; }

    print FHLIST   $id1."\t".$rmsd."\t".$h_info{$id1}{"length"}."\t".$h_info{$id1}{"type"}."\n";
    print FHLISTHTML "<TR><TD>".$id1."</TD><TD>".$rmsd."</TD><TD>".$h_info{$id1}{"length"}."</TD><TD>".$h_info{$id1}{"type"}."</TD>\n";
    $lineclust=$id1."\t";
    $lineclustscore=$id1."\t";
    foreach $id2 (sort keys %{ $h_clusters{$id1} } ){
	next if($id2 eq $id1);
	$lineclust.=$id2.",";
	$lineclustscore.=$h_clusters{$id1}{$id2}.",";
    }
    $lineclust=~s/\,$//;
    $lineclustscore=~s/\,$//;
    print FHCLUST $lineclust,"\n";
    print FHCLUSTS $lineclustscore,"\n";
}
print FHLISTHTML "</TABLE></html>";
#======================================================================
sub read_relationship_hash{
    my $sbr='read_relationship_hash';
    my ($rdbFileIn,$clust_field,$threshold,$rh_ids)=@_;
    die "$sbr: arguments not defined, stopped" 
	if(! defined $rdbFileIn || ! defined $clust_field || ! defined $threshold);
    my ($val,$lineCt,$id1,$id2);
    my (%h_col2name,%h_data,%h_name2col);
    my (@l_data);

    $lineCt=0;
    open(FHIN, $rdbFileIn) || 
	die "failed to open rdbFileIn=$rdbFileIn, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	$lineCt++;
	s/\n$//;
	@l_data=split(/\t/,$_);
	if($lineCt ==1){
	    for $i (0 .. $#l_data){
		$h_col2name{$i}=$l_data[$i];
		$h_name2col{ $l_data[$i] }= $i;
	    }
	    next;
	}
	$val=$l_data[ $h_name2col{ $clust_field } ];
	die "val not found for clust_field >$clust_field< in line: $_" 
	    if(! defined $val);
	$id1=$l_data[0]; $id2=$l_data[1];
	if(! defined $$rh_ids{$id1}){
	    #print "info: $id1 not considered\n";
	    next;
	}
	    
	if(! defined $$rh_ids{$id2}){
	    #print "info: $id2 not considered\n";
	    next;
	}
	$h_data{$id1}{$id2}=$val if($val >= $threshold);
	#print "id: $l_data[0]\n" if($l_data[0] !~/^d\w{6,6}/);
    }
    close FHIN;

    foreach $id (keys %{ $rh_ids }){
	if(! defined $h_data{$id}){
	    die "rdb entry for query $id from among ids to consider not found, stopped";
	}
    }

    return(\%h_data);
}
#====================================================================

#=====================================================================
#single linkage clustering of hash %h_data
sub cluster_single_linkage{
    local ($rh_data)=@_;
    my ($countinue,$clusterNo,$firstkey,$getsubkeys);
    my (@allclusterkeys,@newsubkeys);
    my (%h_clusters);

    $continue=1; $clusterNo=0;
    while( $continue==1 ){
	($firstkey)=&get_one_key($rh_data);
	if(! defined $firstkey){ $continue=0; last; } 
	$clusterNo++;
	$getsubkeys=1;
	@allclusterkeys=($firstkey);
	@newsubkeys=($firstkey);   #initialize subkeys to search for new subkeys
	while( $getsubkeys==1){
	    @newsubkeys           =&get_subkeys_of_keys($rh_data,@newsubkeys);
	    if($#newsubkeys < 0)  {  $getsubkeys=0; last;  }
	    push @allclusterkeys, @newsubkeys;
	}
	#$size       =$#allclusterkeys +1;
	#$pick1      =int (rand $size) ;
	#$clusterRep =$allclusterkeys[ $pick1 ];
	if(defined $h_clusters{ $clusterNo } ){
	    die "scr: h_clusters{ $firstkey } already defined, that should not have happened, stopped";
	}
	foreach $it (@allclusterkeys){
	    #$h_clusters{$clusterNo}{$it}=1;
	    $h_clusters{ $clusterNo }{ $it }=1;
	}
    }
    return (\%h_clusters);

#----------------------------------------------------------------
    sub get_subkeys_of_keys{
	my ($rh,@keys)=@_;
	my (@moresubkeys,@newsubkeys);
	foreach $key (@keys){
	    @moresubkeys=keys %{ $rh -> {$key} };
	    delete $$rh{$key};
	    if(exists $$rh{$key}) { die "ERROR: failed to delete key $key, stopped"; }
	    next if ($#moresubkeys < 0);
	    push @newsubkeys,@moresubkeys;
	}
	return(@newsubkeys);
    }
#----------------------------------------------------------------
#----------------------------------------------------------------
sub get_one_key{
    my ($rh)=@_;
    my ($ct,$id);
    $ct=0;
    foreach $key (keys %{ $rh } ){
	$ct++; $id=$key;
	last if($ct ==1);
    }
    if(! defined $id) { return; }
    else              { return $id; }
} 
#---------------------------------------------------------------
}
#=========================================================================

#==========================================================================
sub cluster_family_size_order{
    my $sbr='cluster_family_size_order';
    my ($rh_data,$order)=@_;
    die "$sbr: h_data or order argument not defined, stopped"
	if(! defined $rh_data || ! defined $order );
    
    my ($size);
    my (%h_clusters,%h_family_sizes,%h_grabed);
    my (@sorted);

    foreach $id1 (keys %{ $rh_data } ){
	@tmp=keys %{ $rh_data -> {$id1} };
	$size=$#tmp + 1;
	$h_family_sizes{$id1}=$size;
    }

    foreach $id1 (keys %{ $rh_data } ){
	die "h_info for $id1 not defined, stopped"
	    if(! defined $h_info{$id1});
    }
    #@tmp=sort keys %h_info;
    #foreach $it (@tmp){ 
#	push @tmp1, $h_info{$it}{"length"}; 
#	push @tmp2, $h_info{$it}{"rmsd"}; 
#    }
#    print "lengths: @tmp1, $#tmp1\n";
#    print "rmsds: @tmp2, $#tmp2\n";
#    exit;

    if($order =~ /increa/){
	@sorted=sort { 
	    $h_info{$a}{"typeVal"} <=> $h_info{$b}{"typeVal"}
	    or $h_family_sizes{$a} <=> $h_family_sizes{$b} 
	    or $h_info{$b}{"length"} <=> $h_info{$a}{"length"}
	    or $h_info{$a}{"rmsd"} <=> $h_info{$b}{"rmsd"}
	    or $a cmp $b
	    } keys %{ $rh_data } ;
    }
    elsif($order =~ /decrea/){
	@sorted=sort { 
	    $h_info{$a}{"typeVal"} <=> $h_info{$b}{"typeVal"}
	    or $h_family_sizes{$b} <=> $h_family_sizes{$a} 
	    or $h_info{$b}{"length"} <=> $h_info{$a}{"length"}
	    or $h_info{$a}{"rmsd"} <=> $h_info{$b}{"rmsd"}
	    or $a cmp $b
	    } keys %{ $rh_data } ;
    }
    else{ die "$sbr: order parameter=$order not understood, stopped"; }

    undef %h_family_sizes;

    foreach $id1 (@sorted){
	next if( defined $h_grabed{$id1} ); #skipping those already included earlier
	$h_grabed{$id1}=1;
	$h_clusters{$id1}{$id1}=1;
	
	foreach $id (keys %{ $rh_data -> {$id1} } ){
	    if(! defined $h_grabed{$id} ){
		$h_clusters{$id1}{$id}=$$rh_data{$id1}{$id};
		$h_grabed{$id}=1;
	    }
	}
	delete $$rh_data{$id1};
    } 
    return (\%h_clusters);
    undef %h_grabed;
}
#===================================================================================
#=====================================================================
#complete linkage clustering of hash %h_data
#assumes h_data is symmetric (that is redundant)
sub cluster_complete_linkage{
    local ($rh_data)=@_;
    my ($assigned,$clusterMemb,$clusterNo,$currentClustNo,
	$newid,$newMemb,$nextClustNo);
    my (@branches);
    my (%h_clusters,%h_branchness);
    
    #first order hash according to number of keys
    foreach $id (keys %{ $rh_data } ){
	@branches    =keys %{ $rh_data -> {$id} };
	$h_branchness{$id}  =$#branches + 1;  
    }

    foreach $newid ( sort { $h_branchness{$b} <=> $h_branchness{$a} } keys %h_branchness ){
	#check if it can be assinged to already existing cluster
	$assigned=$currentClustNo=0;
	foreach $clusterNo ( sort { $a <=> $b } keys %h_clusters ){
	    $newMemb=0; $currentClustNo=$clusterNo;
	    foreach $clusterMemb ( keys %{ $h_clusters{ $clusterNo } } ){
		if(! defined $rh_data -> {$newid} -> {$clusterMemb} ){
		    $newMemb=0; last;
		}
		else{ $newMemb=1; }
	    }
	    if($newMemb){ 
		$h_clusters{ $clusterNo }{ $newid }=1;
		$assigned=1; last;
	    }
	}
	if(! $assigned){ 
	    $nextClustNo=$currentClustNo + 1;
	    $h_clusters{ $nextClustNo }{ $newid }=1;
	}
    } 
    return(\%h_clusters);
}
#=================================================================================


