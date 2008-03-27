#! /usr/sbin/perl
#
#
#======================================================================
unshift (@INC, "/home/schneider/perl") ;
require "ut.pl" ;

$zero = $0 ;
$zero =~ s,.*/,, ;
$| = 1 ;
$this_dir = `pwd` ; chop $this_dir ; $this_dir = $this_dir . "/" ;

if ($#ARGV < 0) {
	print "$#ARGV" ;
	&usage() ;
	exit(1) ;
}

sub usage {
	print <<EOS ;

Usage: 
$zero list_of_filenames
EOS
}
$list_name     = shift ;
$options       = join(' ',@ARGV);

&open_file("LIST","<$list_name");

while (<LIST>) {
   chop ;
   $file_name = $_ ;

   eval "\$command=\"cp $file_name .\"" ;
print "command: $command\n" ;
   &run_program("$command") ;
}
close (LIST);
exit;