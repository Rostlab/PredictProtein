#!/usr/bin/perl

@a =`ls -1 *.map.`;
for (@a){
    $q = $_;$p=$_;$p=~ s/.map.//; $q =~ s/predict/pred/; $q=~ s/.map.//;chomp $q; chomp $p;
    $s =  "mv /home/ppuser/server/work/$p /home/ppuser/server/xch/prd/$q\n";
    print $s;
}
