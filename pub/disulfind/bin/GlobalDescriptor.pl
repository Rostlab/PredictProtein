#!/usr/bin/perl

if( @ARGV<4 ) {
  printf STDERR "Usage: $0 <mean freq file> <stddev freq file> <mean-seq-size file> <pssm file>\n";
  exit -1;
}

$mean_freq_file = $ARGV[0];
$stddev_freq_file = $ARGV[1];
$mean_seq_size_file = $ARGV[2];
$pssm_file = $ARGV[3];

# read global frequencies
open(MEANFREQS, "<", $mean_freq_file);
@mean_freqs = split(" ", <MEANFREQS>);

open(STDDEVFREQS, "<", $stddev_freq_file);
@stddev_freqs = split(" ", <STDDEVFREQS>);

# read global frequencies
open(MEANSEQSIZE, "<", $mean_seq_size_file);
@mean_seq_size = split(" ", <MEANSEQSIZE>);

# calculate local frequencies
open(LOCALFREQS, "prot_reader -t PSI2 -f $pssm_file -a | frequenciesAA.pl|");
@local_freqs = split(" ", <LOCALFREQS>);

# calculate sequence size
open(SEQSIZE, "prot_reader -t PSI2 -f $pssm_file -a | wc | tr -s ' ' | cut -d ' ' -f 2|");
@seq_size = split(" ", <SEQSIZE>);

# calculate number of cysteine
open(NOCYS, "prot_reader -t PSI2 -f $pssm_file -a | grep 'C' | wc | tr -s ' ' | cut -d ' ' -f 2|");
@no_cys = split(" ", <NOCYS>);

# calculate cystein conservation
open(CYSCONS, "prot_reader -t PSI2 -f $pssm_file -a -r  -R 1 | cut -d ' ' -f 1,14 | grep 'C' | cut -d ' ' -f 2 | tr '\n' ' '| tr -s ' '|");
@cys_cons = split(" ", <CYSCONS>);

# calculate descriptors

# relative AA frequencies
for( $i=0; $i<20; $i++ ) {
  $desc = ($local_freqs[$i]-$mean_freqs[$i])/$stddev_freqs[$i];
  print "$desc ";
}

# relative sequence size
$desc = log($seq_size[0]/$mean_seq_size[$0]);
print "$desc ";

# relative number of cysteines
$desc = $no_cys[0]/20;
print "$desc ";
$desc = $no_cys[0]/$seq_size[0];
print "$desc ";

# parity
$desc = $no_cys[0] % 2;
print "$desc ";

# cystein conservation
if( $no_cys[0]>0 ) {
  for( $i=0; $i<5; $i++ ) {
    $bar[$i] = 0;
  }
  for( $i=0; $i<@cys_cons; $i++ ) {
    if( $cys_cons[$i]<=0.2 )    { $bars[0]++; }
    elsif( $cys_cons[$i]<=0.4 ) { $bars[1]++; }
    elsif( $cys_cons[$i]<=0.6 ) { $bars[2]++; }
    elsif( $cys_cons[$i]<=0.8 ) { $bars[3]++; }
    else                        { $bars[4]++; }
  }  
  for( $i=0; $i<5; $i++ ) {
    $desc = $bars[$i]/$no_cys[0];
    print "$desc ";
  }
}
else {
  print "0 0 0 0 0 "
}

print "\n";

