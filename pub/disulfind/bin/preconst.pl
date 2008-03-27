#!/usr/bin/perl

$char='y';
if( @ARGV>=1 ) {
  $char=$ARGV[0];
}

$rows=0;
if( @ARGV>=2 ) {
  $rows=$ARGV[1];
}

if( $rows>0 ) {
  for( $r=0; $r<$rows; $r++ ) {
    print "$char\n";
  }
}
else {
  while( defined($row=<STDIN>)) {
    chomp($row);
    print "$char $row\n";
  }
}
