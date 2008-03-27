#!/usr/local/bin/perl -w
require "importenv.pl";;

$pid = $$;

$file = $HOME."/metaserver/pid/handle.".$pid;
print "file: $file\n";
#system("touch $file");

open(FILE,"> $file"); 
while(<STDIN>) {

    print FILE $_;
    print $_;
    
}
print FILE "$1 done\n";
print "..done\n";
close(FILE);

