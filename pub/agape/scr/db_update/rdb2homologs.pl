#! /usr/bin/perl -w

($rdb,$queryList,$dbList)=@ARGV;

die "arguments not defined: rdb=$rdb, queryList=$queryList, dbList=$dbList, stopped"
    if(! defined $rdb || ! defined $queryList || ! defined $dbList);

$EvalThresh=0.1;
$hsspThresh=101;

open(FHIN,$queryList) ||
    die "failed to open file=$queryList, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    s/\s*$//;
    $h_allQueries{$_}=1;
}
close FHIN;


open(FHIN,$dbList) ||
    die "failed to open file=$dbList, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    s/\s*$//;
    $h_allSubjects{$_}=1;
}
close FHIN;


open(FHIN,$rdb) ||
    die "failed to open file=$rdb, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    if(/^id1/){
	die "wrong format, stopped"
	    if($_ !~ /id1\tid2\tlali\tpide\tdist\tprob\tscore/);
	next;
    }
    s/\s*$//;
    foreach $it ($id1,$id2,$lali,$pide,$dist,$Eval,$score){
	undef $it;
    }
    ($id1,$id2,$lali,$pide,$dist,$Eval,$score)=split(/\t/,$_);
    $h_foundQueries{$id1}=1;
    if($dist >= $hsspThresh || $Eval <= $EvalThresh){
	$h_foundSubjects{$id2}=1;
	$h_homos{$id1}{$id2}=1;
    }
}
close FHIN;
     
@l_tmp=();
foreach $query ( sort keys %h_allQueries){
    if(! defined $h_foundQueries{$query} ){ 
	push @l_tmp, $query;
	$h_homos{$query}{$query}=1; #include self
    }
}
$tmp=join "\n", @l_tmp;
print "these ids were not found among queries (presumably orphans):\n";
print "$tmp\n";


@l_tmp=();
foreach $subject ( sort keys %h_allSubjects ){
    if(! defined $h_foundSubjects{$subject} ){ 
	push @l_tmp, $subject;
    }
}
$tmpOut=join "\n", @l_tmp;
$tmp2=$#l_tmp+1;
print "$tmp2 ids in the database were not linked to any query\n";
$fileOut=$rdb; $fileOut=~s/^.*\///; $fileOut="Out-ids-left-".$fileOut;
open(FHOUT,">".$fileOut) || 
    die "failed to open fileOut=$fileOut, stopped";
print FHOUT $tmpOut;
close FHOUT;



$fileOut=$rdb; $fileOut=~s/^.*\///; $fileOut="Out-homologs-".$fileOut;
open(FHOUT,">".$fileOut) || 
    die "failed to open fileOut=$fileOut, stopped";
foreach $query (sort keys %h_homos){
    @l_homos=sort keys %{ $h_homos{$query} };
    $line=join ",", @l_homos;
    $line=$query."\t".$line."\n";
    print FHOUT $line;
}
close FHOUT;
    
