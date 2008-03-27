#!/bin/sh

# Parameters: <fasta file> <psiblast_workdir> <protname>
fastafile=$1
workdir=$2
prot=$3
blastpgp -d $workdir/sp+trembl -i $fastafile -j 2 -a 2 -C $workdir/tmp/$prot.chk -Q $workdir/Pssm/$prot > $workdir/Alignments/$prot

bzip2 -f $workdir/Alignments/$prot
