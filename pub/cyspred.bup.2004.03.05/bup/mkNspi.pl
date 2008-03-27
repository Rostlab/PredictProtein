#!/usr/local/bin/perl -w
#
#
# read a sequence and write Nspi
# 


$num=1;
$cys=0;
while(<>) {
   $len=length($_);
   tr/a-z/A-Z/;
   for($i=0; $i < $len; $i++) {
      $c=substr($_,$i,1);   
      if($c=~/[A-Z]/) {
#         print "$c\n";
          if($c eq "C") { $pos[$cys]=$num; $cys++;}
          $num++;
      }
   }
}
print "### SS\n";
print "_\t0\n";   
print "### SH\n";
print "$cys\n";
for($c=0; $c <$cys; $c++) {
   print "_\t$pos[$c]\n";
}
 
