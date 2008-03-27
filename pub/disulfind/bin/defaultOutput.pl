#!/usr/bin/perl

if( @ARGV<2 ) {
  printf STDERR "Usage: $0 <sequence> <id>\n";
  exit -1;
}

#primary sequence
my $sequence = $ARGV[0];
my $noaa = length($sequence);
my $nobonded = 0;

#make output

printf "-------------------------------------------------------------------------------\n";
printf "              Cysteines Bonding State and Connectivity Predictor               \n";
printf "-------------------------------------------------------------------------------\n";
printf "\n\n";

printf "Chain identifier: $ARGV[2]\n\n\n";

printf "$sequence\n\n";

printf "The sequence contains no cysteine !!\n\n";

printf "-------------------------------------------------------------------------------\n";
printf "Please cite:\n\n";
printf "P. Frasconi, A. Passerini, and A. Vullo.\n";
printf "\"A Two-Stage SVM Architecture for Predicting the Disulfide Bonding State of Cysteines\"\n";
printf "Proc. IEEE Workshop on Neural Networks for Signal Processing, pp. 25-34, 2002.\n\n";
printf "A. Vullo and P. Frasconi.\n";
printf "\"Disulfide Connectivity Prediction using Recursive Neural Networks and Evolutionary Information\"\n";
printf "Bioinformatics, 20, 653-659, 2004.\n\n";

printf "Questions and comments are very appreciated.\n";
printf "Please, send email to: cystein\@dsi.unifi.it\n\n";

printf "Created by members of the Machine Learning and\n";
printf "Neural Network Group, Universita' di Firenze\n\n";

printf "The server is hosted at the Department of Systems and\n";
printf "Computer Science (DSI), Faculty of Engineering,\n";
printf "Universita' di Firenze, Italy\n";
printf "-------------------------------------------------------------------------------\n";

