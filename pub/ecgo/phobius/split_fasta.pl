#!/usr/bin/perl

# Andrew Kernytsky
# Columbia University
#
# Splits a FASTA file given as input into the number of chunk files specified 

$finame = shift;
$chunks = shift;

if ($finame eq "") {
    print "Usage: perl $0 input_filename chunks\n";
    exit;
}
if ($chunks <= 1) {
    print "Chunk size should be an integer greater than one\n";
}

open FIN, $finame or die "Couldn't open input file $finame\n";
$totalseqs=0;
while (<FIN>) {
    if (/^>/) { $totalseqs++; }
    ### $totalseqs++;
}
close FIN;

print "Found $totalseqs sequences in file $finame\n";

open FIN, $finame or die "Couldn't open input file $finame\n";
$chunksize = $totalseqs / $chunks;
$j=-1;
for ($i=1; $i<=$chunks; $i++) {
    $startseq = int (($i-1) * $chunksize);
    $endseq = int (($i * $chunksize) - 1);
    if ($i == $chunks) {
	if ($endseq != ($totalseqs-1)) {
	    die "Last chunk doesn't end correctly $i $totalseqs\n";
	}
    }
    print "Processing chunk $i from $startseq to $endseq\n";

    open FOUT, ">$finame.$i" or die "Couldn't open output file $finame.$i\n";
    if ($i != 1) {print FOUT $last_line;}
    $j=$startseq;
    while (<FIN>) {
	### $j++;
	if (/^>/) {$j++;}
	### # Following 3 lines added to make a list file for psi_profsec.pl
	### chomp;
	### s/^>//;
	### $_ = uc $_;
	### $_ = "/home/kernytsky/enzyme/prof/splitSwiss/".$_.".fa\n";
	if ($j > $endseq) {last;}
	#if ($j > ($startseq+10)) {last;} #temp to make short lists for testing
	print FOUT;
    }
    $last_line = $_;

    close FOUT;
}
