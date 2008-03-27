#!/usr/bin/perl

while(defined($row = <STDIN>)){

  chomp($row);
  @elements = split(" ", $row);
  
  for( $i=1; $i<=@elements; $i++ ) {
    if( $elements[$i-1] != 0 ) {
      print "$i:$elements[$i-1] ";
    }
  }
  print "\n";

}
