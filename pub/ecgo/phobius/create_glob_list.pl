#!/usr/bin/perl

open LIST, "glob_list.txt" or die "glob_list\n";

while (<LIST>) {
    chomp;
    if ($_ eq "") {next;}
    
    @temp = split /\_/;
    if (/(.*?)_(.)/) {
	$_ = $1."_".uc($2);
    }
    $pdb_file = "/data/derived/big/splitPdb/$_.f";#$temp[0]_".uc($temp[1]);
    if (-e $pdb_file) {
	$cmd = "cat $pdb_file >>glob.f";
	print "$cmd\n";
	system $cmd;
    }else{
	print "### File not found $pdb_file\n";
    }

}
