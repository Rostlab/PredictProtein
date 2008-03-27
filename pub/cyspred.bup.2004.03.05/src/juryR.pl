#!/usr/local/bin/perl -w
#
# genera la giuria di 6 reti
# 

@net=(" ","Conservation+ Entropy", "Conservation+ Entropy + Charges", "Charge", " Conservation+ Entropy+Hydrophobicity"," Conservation+ Entropy + Charges + Hydrophobicity");
# lettura file con l'indice delle cys
open(F,"$ARGV[0]") || die "$0 Can't open $ARGV[0] Line 8\n";
$c=0;
while(<F>) {
   if(/^_\t(\d+)/)  {
      if($1 != 0) {
#         print "$1\n";
         $ncys[$c]=$1;
         $c++;         
      }
   }
}
close(F);


# LETTURA DEI FILE CON LA PREDIZIONI
print "PREDICTION OF BONDING STATE OF CYSTEINES\n";
for($i=1; $i <=$#ARGV; $i++) {
#    print STDERR $ARGV[$i],"\n";
    open(F,"$ARGV[$i]") || die "$0:Line 26: Can't open $ARGV[$i]\n";
    print "Network N. $i  $net[$i]\n"; 
    print "N.cys\tProb.SS\t\tProb.SH\n";
    $c=0;
    do {
       $_=<F>;
       print $_."\n";
       if(/^\d+/) {
          @v=split;   
          $vet{"$i;$c;S"}=$v[1]; $vet{"$i;$c;H"}=$v[2];
          print "$ncys[$c]\t$v[1]\t$v[2]\n";
          $c++;
       }
    }while(/^\d+/);
    print "###################\n";
    close(F); 
}
print "JURY AMONG THE DIFFERENT NETWORKS\n";
print "\tProb.SS\tProb.SH\n";
print "N.cys\tBONDED\tNON-BONDED\tDISULFIDE\n";
for($j=0; $j<$c; $j++) {
   $cc=$ch=0;
   for($i=1; $i <=$#ARGV; $i++) {
      $cc+=$vet{"$i;$j;S"}; $ch+=$vet{"$i;$j;H"};
#      printf("%s  %s | %d\n",$vet{"$i;$j;S"},$vet{"$i;$j;H"},$c);
   }
   $cc/=$#ARGV; $ch/=$#ARGV;
   printf "%d\t%.3f\t%.3f\t",$ncys[$j], $cc,$ch;
   if($cc>$ch) { print "\tYES\n"}
   else{print "\tNO \n";}
}

print "#==============================================#\n";
