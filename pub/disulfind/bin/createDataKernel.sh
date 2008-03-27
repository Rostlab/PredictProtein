#!/bin/sh
if [ $# -lt 6 ]
then
    echo "Usage: $0 <k> <protein_name> <mean freq file> <stddev freq file> <mean-seq-size file> <pssm_dir>" 
    exit -1
fi

k=$1
prot=$2
mean_freq=$3
stddev_freq=$4
mean_seq_size=$5
pssm_dir=$6

    pssm_file="$pssm_dir/$prot"
    pastePipe.pl "prot_reader -t PSI2 -f $pssm_file -a" "prot_reader -t PSI2 -f $pssm_file -r  -R 1 | makeWindow.pl $k" | grep "C" |  cut -d ' ' -f 2- | makeSparseVector.pl | preconst.pl 0

