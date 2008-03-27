#! /usr/bin/perl -w


($list)=@ARGV;



if($list=~/\.list/){
    open(FHIN,$list) || 
	die "failed to open list file=$list, stopped";
    while(<FHIN>){
	next if(/^\s*$|^\#/);
	($file)=($_=~/^(\S+)/);
	$h_fastasIn{$file}=1;
    }
    close FHIN;
}else{
    $h_fastasIn{$list}=1;
}

$agape_exe="/home/dudek/server/pub/agape/scr/agape_new.pl";
$dirOut="/home/dudek/agape_uni/";

foreach $fasta (sort keys %h_fastasIn){
    $proc=$fasta; $proc=~s/.*\///; $proc=~s/\..*//;
    $cmd=$agape_exe." ".$proc." ".$fasta." ".$dirOut;
    system($cmd);
}
