#! /usr/bin/perl -w

($f1,$f2)=@ARGV;

open(FH,$f1) || die "did not open $f1";
while(<FH>){
    next if(/^>/);
    $seq1.=$_;
}
close FH;
$seq1=~s/\s//g;


open(FH,$f2) || die "did not open $f2";
while(<FH>){
    next if(/^>/);
    $seq2.=$_;
}
close FH;
$seq2=~s/\s//g;

if($seq1 ne $seq2){
    print "$f1 $f2 fastas differ\n";
    print $seq1."\n".$seq2."\n"; 
}else{ print "$f1 $f2 same\n"; }
