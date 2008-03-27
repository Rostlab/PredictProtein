#!/usr/bin/perl

use IO::File;

if( @ARGV<1 ) {
  print "usage: $0 <command1> [<command2>]\n";
  exit(-1);
}

$nopipes=0;
if( @ARGV==1 ) {
  $nopipes=2;
  $PIPES[0] = 'fh0';
  $PIPES[1] = 'fh1';
  open($PIPES[0],'<&STDIN');
  open($PIPES[1],"$ARGV[0]|") or die("can't run command <$ARGV[0]>: $!");
}
else {
  $nopipes = @ARGV;
  for( $i=0; $i<@ARGV; $i++ ) {
    $PIPES[$i] = 'fh'.$i;
    open($PIPES[$i],"$ARGV[$i]|") or die("can't run command <$ARGV[$i]>: $!");
  }
}

$end=0;
while($end==0) {
  $end = 1;
  for( $i=0; $i<$nopipes; $i++ ) {
    $fh = $PIPES[$i];
    if( defined($row=<$fh>) ) {
      $end = 0;
      chomp($row);
      print $row . " ";
    }
  }
  if( $end==0 ) {
    print "\n";
  }
}

for( $i=0; $i<$nopipes; $i++ ) {
  close(<$PIPES[$i]>);
}

