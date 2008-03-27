#!/usr/bin/perl


#open (FI,"phd.log");
open (FI,$ARGV[0]);
my %h;
while (<FI>){
    @line = split(/\s/, $_);
    @line = reverse @line;
    $email = pop @line; 
#    print "$email\n";
    $h{$email}++;
}

while( my ($k, $v) = each %h ) {
    print "$k\t$v\n";
}
