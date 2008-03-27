#!/usr/bin/perl
##!/usr/local/bin/perl -w
#
# ASP v1.0 3/7/2001
#
# This is a perl implementation of ASP, a conformational 
# switch prediction program developed by MM Young, K
# Kirshenbaum, KA Dill and S Highsmith.
#
# Reference :
# Malin M. Young, Kent Kirshenbaum, Ken A. Dill, Stefan Highsmith.
# "Predicting Conformational Switches in Proteins". Protein Science
# 8(9):1752-1764. 1999.
#
# Usage: asp.pl [-ws=<window size>] [-z=<z score cutoff>] 
#         [-min=<min zscore>] [-in=<PHDoutput file>] [-out=<output file>]

# load module for option parsing
use Getopt::Long;

# get the following options:
# -h   print help screen
# -ws=<window size>   an integer value
# -z=<z score cutoff> a real value
# -min=<min mu dPr> a real value
# -in=<input file>   defaults to first arg if -in is not given, or to stdin
# -out=<output file> defaults to standard output

GetOptions qw(h ws=i z=f min=f in=s out=s err=s);

# set default values for the options
$opt_h   =  0 unless $opt_h;
$opt_ws  =  5 unless defined $opt_ws;
$opt_z   = -1.75 unless defined $opt_z;
$opt_min =  9.0 unless defined $opt_min;
$opt_in  =  ""  unless $opt_in;
$opt_out = "-" unless $opt_out;
$opt_err = "" unless $opt_err;

# print help if -h is given
($name = $0) =~ s!.*/!!;  # trim the leading path of the script name
if($opt_h) {
  print STDERR
      "$name:  A conformational switch prediction program\n",
      "Usage:  $name [options] [-in infile] [-out outfile]\n",
      "  Opt:  -h          print this help\n",
      "        -ws  <int>  set window size (default: 5)\n",
      "        -z   <real> set z score cutoff (default: -1.75)\n",
      "        -min <real> set minimum mu dPr score (default: 9.0)\n",
      "        -in  <file> read input from the given file.\n",
      "                    If -in is not given, the first argument is used\n",
      "                    If no arguments are given, read standard input\n",
      "        -out <file> write output to the given file (default: stdout)\n",
      "        -err <file> write err message to the given file (default: sterr)\n";
  exit(1);
}

# Now we can begin
#
# First, find where we're getting our input from
if($opt_in eq "") {
  # if any arguments remain, use the first one as the input file
  if(@ARGV > 0) {
    $opt_in = "$ARGV[0]\n";
  }
  # otherwise, read from standard input
  else {
    $opt_in = "-";
  }
}

				# err message
if ( $opt_err ) {
    $fhErr = "ERR";
    open ( $fhErr, ">$opt_err" ) or die "cannot write to err file:$!";
} else {
    $fhErr = "STDERR";
}


# Open the input and output files
# $! is a special variable that reports the error of why a command failed
#open IN,  "<$opt_in"  or die("Failed to open input $opt_in: $!\n");
open OUT, ">$opt_out" or die("Failed to open output $opt_out: $!\n");

print OUT "\n\nAmbivalent Sequence Predictor (ASP v1.0) mmy\n\n";

# 1) Parse the PHD output file and read secondary structure predictions
#    into arrays

# initialize strings
$seq = $prH = $prE = $prL = "";

# parse PHD output file
#while(<IN>) {   # read the file line by line into the special variable $_
  # first, trim off all leading spaces (we don't need them anyway)
#  $_ =~ s/^\s*//g;
  # and trim off any trailing newlines
#  chomp;

  # the rest is basically a series of tests for the beginning of the line

  # if the line begins with a series of dots, it is a number bar 
#  push @head, $_ if($_ =~ /^\s*\.\.\.\./);

  # if the line starts with AA, this is a continuation of the sequence
  # so we'll want to collect the part between the "|"s
#  $seq .= &pipe_delimited($_) if($_ =~ /^\s*AA/);
#  print $seq;
  
  # prH information starts with prH
#  $prH .= &pipe_delimited($_) if($_ =~ /^\s*prH sec/);
#  $prH .= &pipe_delimited($_) if($_ =~ /pH/);

  # prE information starts with prE
#  $prE .= &pipe_delimited($_) if($_ =~ /^\s*prE sec/);
#  $prE .= &pipe_delimited($_) if($_ =~ /pE/);

  # prL information starts with prL
#  $prL .= &pipe_delimited($_) if($_ =~ /^\s*prL sec/);
#  $prL .= &pipe_delimited($_) if($_ =~ /pL/);
#}
#close IN;			# remember to close file handle

#print "prl=$prL\npre=$prE\nprl=$prL\n";
# check to make sure that the input file contains PHD predictions
#unless($seq and $prH and $prE and $prL) {
#  die "\n\nERROR: input file is not in PHD format.\n\n";
#}

#
# 2) Make magic

# convert strings into arrays for processing
#$prof_filename=$ARGV[0];
use lib '/nfs/data5/users/ppuser/server/pub/asp';
use prof;
$prof_res = prof::extract_preds($opt_in);

$seq = $prof_res->[0];
$prH = $prof_res->[3];
$prE = $prof_res->[4];
$prL = $prof_res->[5];
#print $prH;
#die;

@seqarr = split '', $prof_res->[0];
@prharr = split '', $prof_res->[3];
@prearr = split '', $prof_res->[4];
@prlarr = split '', $prof_res->[5];






#@prharr = split '', $prH;
#@prearr = split '', $prE;
#@prlarr = split '', $prL;




# Bound check parameters
# Set ws to 5 if <0 
if($opt_ws < 0) {
  print $fhErr 
    "WARNING:  Window size $opt_ws is <0, resetting it to the default (5).\n";
  $opt_ws=5;
}

# Warn if $opt_min is out of bounds and reset to default
if(($opt_min<0)||($opt_min>18)) {
  print $fhErr 
    "WARNING:  Min mu dPr value $opt_min is out of bounds, resetting it to the default (9).\n";
  $opt_min=9;
}

# if ws>sequence length, set it to the default (5).
if($opt_ws > @seqarr) {
  print $fhErr 
    "WARNING:  Window size $opt_ws is >sequence length, resetting it to the default (5).\n";
  $opt_ws=5;
}

# Set ws to an odd number if it is even
if(($opt_ws % 2) == 0) {
  print $fhErr "WARNING:  Window size $opt_ws is even, incrementing by one.\n";
  $opt_ws++;
}

print OUT "\n";

# if the same sequence appeared multiple times, it needs to be trimmed
if((scalar(@seqarr) / scalar(@prharr)) > 1) {
  @seqarr = @seqarr[0..$#prharr];
  $seq = substr($seq, 0, scalar(@prharr));

  #print STDERR "DEBUG:  length(\$seq) == ", length($seq), "\n";
  #print STDERR "        scalar(\@seqarr) == ", scalar(@seqarr), "\n";
}


# make sure that all the arrays are of identical length
unless((scalar(@prearr) == scalar(@prharr)) and
       (scalar(@prlarr) == scalar(@prharr)))
{
  printf $fhErr
    "BUMMER:  The sequence arrays are not of identical length.\n",
    "  scalar(@seqarr) == ", scalar(@seqarr), "\n",
    "  scalar(@prharr) == ", scalar(@prharr), "\n",
    "  scalar(@prearr) == ", scalar(@prearr), "\n",
    "  scalar(@prlarr) == ", scalar(@prlarr), "\n",
    "\n",
    "seqarr == (@seqarr)\n",
    "prharr == (@prharr)\n",
    "prearr == (@prearr)\n",
    "prlarr == (@prlarr)\n";
  exit(2);
}

# calculate the ambivalence score for each position
for($i = 0; $i < @seqarr; ++$i) {
  # get absolute values of the differences
  $HEdiff = abs($prharr[$i] - $prearr[$i]);
  $HLdiff = abs($prharr[$i] - $prlarr[$i]);
  $ELdiff = abs($prearr[$i] - $prlarr[$i]);
  $as[$i] = $HEdiff + $HLdiff + $ELdiff;

}



$hlf = int($opt_ws/2);

# average over the given window size

$seqmean=0;
$seqmin=18;
for($i = 0; $i < @seqarr; ++$i) {
  $lo = $i - $hlf;
  $hi = $i + $hlf;

  $lo = 0 if($lo < 0);
  $hi = scalar(@seqarr) - 1 if $hi >= scalar(@seqarr);

  $sum = 0;
  $width = 0;
  for($j = $lo; $j <= $hi; ++$j) {
    $sum += $as[$j];
    $width++;
  }

  $avgas[$i] = $sum / $width;
  $seqmean += $avgas[$i];

  if($avgas[$i]<$seqmin) {
    $seqmin=$avgas[$i];
  }
}

# exit if the minimum local mean dPr value is > $opt_min
if($seqmin>$opt_min) {
  print OUT 
    "No ambivalent regions found using current settings.\n\n";
  exit(2);
}

# get the global sequence mean
$seqmean=$seqmean/@seqarr;

# calculate the standard deviation
$stdev=0;
for($i = 0; $i < @seqarr; ++$i) {
  # calculate sum of squared differences
  $stdev += ($avgas[$i]-$seqmean)*($avgas[$i]-$seqmean);
}
$stdev = sqrt($stdev/(@seqarr-1));

# calculate the zscore at each position in the sequence 
for($i = 0; $i < @seqarr; ++$i) {
  $zs[$i]= ($avgas[$i]-$seqmean)/$stdev; 
}

#
# 3) Output results

print OUT 
    "Parameters:\n",
    "\tWindow size\t:\t$opt_ws\n",
    "\tMin mu dPr\t:\t$opt_min\n",
    "\tZ-score cutoff\t:\t$opt_z\n\n";
#          "\tInput file\t:\t$opt_in\n",
#          "\tOutput file\t:\t$opt_out\n\n";
printf OUT 
          "\tMean dPr score=%.3f, Standard deviation=%.3f\n\n", $seqmean, $stdev;

$ctr=0;
#print scalar(@seqarr)."\n"x10;
for($i = 0; $i <  scalar(@seqarr); ++$i) {
#for($i = 0; $i < @head; ++$i) {
  # don't bother if there is no useful data left
  last if(($i * 60) >  scalar(@seqarr));
  
  # make sure that we don't go any further along the string than the data reaches
  if(($i + 1)*60 > scalar(@seqarr) ) {
    $stop =  scalar(@seqarr) % 60;
  }
  else {
    $stop = 60;
  }

  $subseq = substr($seq, $i * 60, $stop);
  $subprH = substr($prH, $i * 60, $stop);  
  $subprE = substr($prE, $i * 60, $stop);  
  $subprL = substr($prL, $i * 60, $stop);  

  print OUT "                  $head[$i]\n",
            "         AA      |$subseq|\n",
            "         prH sec |$subprH|\n",
            "         prE sec |$subprE|\n",
            "         prL sec |$subprL|\n",
            "         ASP sec |";

  # print out "S" for a predicted switch region, "." for the rest
  for($j=0; $j<$stop; ++$j) {
    if($zs[$ctr++]<=$opt_z) {
      print OUT "S";
    }
    else {
      print OUT ".";
    }
  }
  print OUT "|\n\n";
}

# output disclaimer
print OUT "\nPlease note: ASP was designed to identify the location of conformational \n",
 "switches in amino acid sequences. It is NOT designed to predict whether \n",
"a given sequence does or does not contain a switch.  For best results,\n",
"ASP should be used on sequences of ",
          "length >150 amino acids with >10 \n",
"sequence homologues in the SWISS-PROT data bank. \n",
"ASP has been validated against a set of globular proteins and may not \n",
"be generally applicable. Please see Young et al., Protein Science \n",
"8(9):1852-64. 1999. for details and for how best to interpret this \n",
"output.  We consider ASP to be experimental at this time, and would \n",
"appreciate any feedback from our users.\n\n"; 
 
close OUT;
close $fhErr;
exit(0);


########
# subroutine to extract the text between given separators

sub pipe_delimited {
  my $inline    = shift;

  my $line = $inline;
  $line =~ s/^.*\|([^|]*)\|.*/$1/;

  return $line;
}

