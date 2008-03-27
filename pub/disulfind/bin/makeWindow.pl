#!/usr/bin/perl

if (@ARGV < 1) {
  die("Too few arguments, need: <k>");
}

$k=$ARGV[0];
$w = 2*$k+1;
$is_init = 0;

$line = 0;
while(defined($row = <STDIN>)){

  chomp($row);
  @elements = split(" ", $row);
  
  #initialize

  if( $is_init==0 ) {
    $is_init = 1;
    $no_elems = @elements;
    $head = -$k;
    $nav = $k;
    
    $zero_elem = "0";
    for( $i=1; $i<$no_elems; $i++ ) {
      $zero_elem = $zero_elem . " 0";
    }

    for($i=0; $i<$w; $i++ ) {
      $window[$i] = $zero_elem;
    }
  }

  #check number of columns

  if( $is_init==1 && $no_elems!=@elements ) {
    die("Inconsistent number of columns in line $line");
  }

  $window[$nav] = $row;

  if( $head>=0 ) {
    for($i=0; $i<$w; $i++) {
      $ind = ($head+$i) % $w;
      print "$window[$ind] ";
    }
    print "\n";
  }

  if( $head<0 ) {
    $head++;
  }
  else {
    $head = ($head+1) % $w;
  }  
  $nav = ($nav+1) % $w;

}

for( $c=0; $c<$k; $c++ ) {
  $window[$nav] = $zero_elem;

  for($i=0; $i<$w; $i++) {
    $ind = ($head+$i) % $w;
    print "$window[$ind] ";
  }
  print "\n";

  $head = ($head+1) % $w;
  $nav = ($nav+1) % $w;
}
