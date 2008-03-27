#!/usr/bin/perl -w 

#this file creates the extracted data files for each of the 
#mutants

#print "temp = $temp\n";
$temp = $ARGV[0];
#$temp =~ s/^([^\/]+\/)*//;
$temp =~ s/.+proc([I|E|B])/$1/;
#print "temp = $temp\n";
open (IN, $ARGV[0]) || die "Can't open $ARGV[0]\n";
open (OUT, ">$ARGV[1]/ProcessedJct$temp");
$processed_dir = $ARGV[1];	
foreach $line (<IN>){
	if ($line =~ /\w/){
		$temp = "";
		$line =~ s/(.+\.[A-Z]\d+[A-Z])(\s+.+)*\n//g;
		$line = $1;
		open (FILE, "$processed_dir/$line") || die "No $line exists\n";
		foreach $d (<FILE>){
			$temp .= $d;
		}
		close FILE;
		print OUT $temp;
	}
}
close IN;
close OUT;
