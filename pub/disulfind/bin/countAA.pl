#!/usr/bin/perl

$AA = "ACDEFGHIKLMNPQRSTVWY";

for ($j=0; $j<20; $j++) {
  $frequencies[$j] = 0;
}

while(defined($row = <STDIN>)){
  chomp($row);
  for($i=0; $i<length($row); $i++ ) {
    $aa = substr($row,$i,1);
    if( $aa ne ' ' ) {
      $id = index($AA, $aa);
      if( $id==-1 ) {
	print STDERR "Unexpected AA code in file, skipped...\n";
      }
      else {
	$frequencies[$id]++;
      }
    }
  }
}

for ($j=0; $j<20; $j++){
  print "$frequencies[$j] ";
}
print "\n";
