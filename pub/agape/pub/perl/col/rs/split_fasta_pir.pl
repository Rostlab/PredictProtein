#!/bin/env perl
# split a fasta file and spit out one pir file per entry....
$f=0;
while(<>) {
    if (/^>(\w+)/) {
	close FILE if($f);
	$f=$1;
	print "$f\n";
	open(FILE,">$f") || warn "$!";
	print FILE $_;
	print FILE substr($_,1);
    } else {
	print FILE $_;
    }
}
close FILE;
