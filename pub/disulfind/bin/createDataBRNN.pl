#!/usr/bin/perl

sub cysteinConservation{
  
  if($_[0] <= 0.2){
    return "1 0 0 0 0";
  }
  elsif($_[0] <= 0.4){
    return "0 1 0 0 0";
  }
  elsif($_[0] <= 0.6){
    return "0 0 1 0 0";
  }
  elsif($_[0] <= 0.8){
    return "0 0 0 1 0";
  }
  return "0 0 0 0 1";
}

if(@ARGV < 4){
  $prog = `basename $0`;
  chomp($prog); 
  print "Usage: \n\t$prog <protein.fasta> <protein.probabilities> <protein.psi2> <protein.output>\n\n";
  exit(-1);
}


$protfile=$ARGV[0];
@probabilities=`cat $ARGV[1]`;
$global_target_dim=0;
$local_target_dim=0;
$pssm_file=$ARGV[2];
$output=$ARGV[3];
$protname=`basename $protfile`;
chomp($protname);

open(OUT, "> $output");
print OUT "id $protname\nglobal_target_dim ${global_target_dim}\nlocal_target_dim ${local_target_dim}\nnodes_input_dim 7\n\n";
$cysdim=`tail +2 $protfile | countAA.pl | awk '{print \$2}'`;
chomp($cysdim);

@cyscon=`pastePipe.pl "prot_reader -t PSI2 -f $pssm_file -a" "prot_reader -t PSI2 -f $pssm_file -r  -R 1" | grep "C" |  cut -d ' ' -f 2-`;
$parity = $cysdim % 2;
$currcons = "0 0 0 0 0";
for($j = 0; $j < $cysdim; $j++){
  chomp($probabilities[$j]);
  if(@cyscon > 0){
    $currcons=cysteinConservation($cyscon[$j]);
  }
  print OUT "node $probabilities[$j] $currcons $parity\n";
}

print OUT "\ngraph (" . scalar(@cyscon) . ") ";
print OUT "\n\n";
for($j = 0; $j < $cysdim; $j++){
  print OUT "$j";
  if($j < $cysdim-1){
    print OUT " " . ($j+1);
  }
  print OUT "\n";
}
close(OUT);

