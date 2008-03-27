#!/usr/sbin/perl
$pwd =`pwd`; chop $pwd ;
eval 'exec /usr/sbin/perl -S $0 ${1+"$@"}'
	if $running_under_some_shell;

require "find.pl";

# Traverse desired filesystems

&find('.');

exit;

sub wanted {
    if ( 
       /^.*\.hssp$/ &&
       (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
       (-M _ > 0.1) ) {
       $name=~ s:^\./:: ;
       print("mv $pwd/$name /data1/hssp_new+0/\n");
    }
}

