#!/usr/local/bin/perl

$file =$ARGV[0];
$cut = $ARGV[1];

open (IN, $file);
open (OUT, ">outFunc");

$count = 0;
foreach $line (<IN>){
	if (!($line =~/[A-Z]|\*/)){
		@line = split (/\s+/, $line);
		$tot = $line[2] - $line[3];
		$atot = 0-$tot;
		if ($tot > $cut){
			print OUT "100 0\n";
		}
		elsif ($atot >$cut){
			print OUT "0 100\n";
	 	}
		else{
			print OUT "50 50\n";
			$count++;
		}
	}
}
print "$count\n";
close IN;
close OUT;

