#!/usr/local/bin/perl -w
#
# genera la giuria di 6 reti
# 

@net=(" ","Profile + Entropy", "Profile + Charges", "Profile + Hydrophobicity", "Profile + Entropy + Charges + Hydrophobicity");
# lettura file con l'indice delle cys

@od=();

# LETTURA DEI FILE CON LA PREDIZIONI
print "PREDICTION OF BONDING STATE OF CYSTEINES\n";
for($i=0; $i <=$#ARGV; $i++) {
#    print " > $ARGV[$i]\n";
    open(F,"$ARGV[$i]") || die "Can't open $ARGV[$i]\n";
    print "Network N. $i  $net[$i]\n"; 
    print "N.cys\tProb.\t\tProb.\n";
    $c=0;
    do {
       $_=<F>;
       if(/^\d+/) {
          @v=split;   
          $vet{"$i;$c;S"}=$v[1]; $vet{"$i;$c;H"}=$v[2];
          $od[$c]=$v[3];
          print "$ncys[$c]\t$v[1]\t$v[2]\n";
          $c++;
       }
    }while(/^\d+/);
    print "###################\n";
    close(F); 
}
$numok=0;
print "JURY AMONG THE DIFFERENT NETWORKS\n";
print "\tProb. \tProb.\n";
print "N.cys\tBONDED\tNON-BONDED\tDISULFIDE\n";
for($j=0; $j<$c; $j++) {
   $cc=$ch=0;
   for($i=0; $i <=$#ARGV; $i++) {
      $cc+=$vet{"$i;$j;S"}; $ch+=$vet{"$i;$j;H"};
#      printf("%s  %s | %d\n",$vet{"$i;$j;S"},$vet{"$i;$j;H"},$c);
   }
   $cc/=@ARGV; $ch/=@ARGV;
   printf "%d\t%.3f\t%.3f\t",$ncys[$j], $cc,$ch;
   if($cc>$ch) { if($od[$j]>0) {$numok++;} print "\tYES\n"}
   else{if($od[$j]==0){ $numok++;} print "\tNO \n";}
}

print "#==============================================#\n";
printf "Jury Prec = %f\n", $numok/$c;
print "#==============================================#\n";
