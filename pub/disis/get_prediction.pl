#!/usr/bin/perl

# Yanay Ofran
# 07/12/2006

# This script takes a .svm-raw file with raw SVM predictions and the post-processing parameters:
# gap stretch crowd and iterations, and writes the resiude-predictions and the number of residues
# predicted to bind DNA in the corresponding .stats file.

if (@ARGV<6){die "Usage: $0 input-file output-file gap stretch crd (iterations-deleted) seq\n"}
@e=@ARGV;
$RAW_SVM_FILE = "$e[0]";
$OUTPUT_FILE = "$e[1]";
$g=$e[2];#diff between output nodes
$sch=$e[3];#half stretch
$cr=$e[4];#crowd
#$nitr=$e[5];
$seq=$e[5];
$crgs=1;#crowd of gs
$topgap=101;#maximal difference between outputnodes;
#print "g=$g sch=$sch cr=$cr seq=$seq\n";
printf "\nMaking $OUTPUT_FILE...";

##s############### RECORD PREDICTIED ###################
$cpp=0;
$pos=0;
foreach $l (`cat $RAW_SVM_FILE`){
    chop $l; # remove new line
    # the neural network gives values in the range -100 to +100
    # the SVM return values in the range -1 to +1: so scale
    $prval[$pos]= $l * 100;
    if ($prval[$pos] > 100) {$prval[$pos]=100;}
    if ($prval[$pos] < -100) {$prval[$pos]=-100;}
    if (($prval[$pos] > $g) and ($prval[$pos] < $topgap)) {
        $pr[$pos]="pp";
        $pp++;
    } else {
        $pr[$pos]="notpp";$np++;
    }
    $pos++;
}

#########################################################
open opF, ">$OUTPUT_FILE";
#printf "\n";
$length = scalar @pr;
for ($i=0;$i<scalar @pr;$i++){
  for ($j=(-$sch);$j<$sch+1;$j++){
    if ((($i+$j)>-1) and (($i+$j)<scalar @pr)){
      if (($pr[$i+$j] eq "pp") or ($pr[$i+$j] eq "PP")){
        $prp[$i]++;
        $sprp[$i]=$sprp[$i]+$prval[$i+$j];
      }
      if ($prval[$i+$j]>=$g){$stval[$i]=$stval[$i]+$prval[$i+$j]}
    }
}
  if (($pr[$i] eq "pp") and (($prp[$i]>$cr-1) or ($sprp[$i]>30.98571*$cr*$sch))){
    $out{pp}[$i]="P";
    $cpp++;
  }
  elsif ($prp[$i]<$cr){$out{pp}[$i]="-"}
  else{$out{pp}[$i]="-"}
  if ($pr[$i] eq "PP"){$out{pp}[$i]="P";$cpp++}
  #print opF "$out{pp}[$i]";
  #printf "$out{pp}[$i]";
}
#print opF "\nP=$cpp";
printf "PP=$pp,NP=$np, Length=$length\n";
print opF "PP=$pp,NP=$np, Len=$length\n";
@s=split (//,$seq);
$seq="";$pp="";
for ($i=1;$i<scalar @s;$i++){
    $blk++;
    if ($blk==41){
        printf "%40s\n%40s\n\n",$seq,$pp;
        printf opF "%40s\n%40s\n\n",$seq,$pp;
        $blk=1;$seq="";$pp="";
    }
    $seq=$seq.$s[$i];
    $pp=$pp."$out{pp}[$i]";
}
print "$seq\n$pp\n\n";
printf opF "$seq\n$pp\n\n";
for ($i=1;$i<scalar @s;$i++){
    $prval[$i]=int $prval[$i];
    print opF "$s[$i] $prval[$i]\n";
    print "$s[$i] $prval[$i]\n";
}
close opF, ">$OP_FILE";
