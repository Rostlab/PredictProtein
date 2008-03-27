#! /usr/sbin/perl
#
#
#======================================================================
unshift (@INC, "/home/schneider/perl") ;
require "ut.pl" ;
$make_profile = "/home/schneide/max/make_profile" ;
$profile_path = "/sander/sander1/schneide/profile/" ;

$zero = $0 ;
$zero =~ s,.*/,, ;
$| = 1 ;

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
   $base_name = $file_name ;
   $base_name =~ s,(.*/),, ;

   $profile_name = $profile_path . $base_name ; 
   $profile_name =~ s/hssp/profile/g ;

   eval "\$command=\"$make_profile , $file_name , $profile_name , profile , weight , eigen , 0.0 , 1.0 , scale , , exit , NO \"" ;
print "command: $command\n" ;
   &run_program("$command") ;
}
close (LIST);
exit;