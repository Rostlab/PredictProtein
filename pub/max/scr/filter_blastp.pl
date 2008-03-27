#!/usr/local/bin/perl
##!/usr/sbin/perl

$p_value_cut = 1.5 ;
$sw_current= $ARGV[0];
$_ = shift ;


$_=<>;

LIST_FOUND:while(<>) {
    if(/^Sequences producing High-scoring Segment Pairs:/) {
	while(<>) {
	    last LIST_FOUND if /\S/;
	}
	last;
    }
}

for(;$_;$_=<>) {
   chop;
   if(/^\s*([\S]+)\s+(.*)\s(\d+)\s+([-x\d.e]+)\s+(\d+)$/) {
     if ($4 < $p_value_cut ) {
       $db_info = $1;
       ($db,$acc,$name)=split(/\|/,$db_info);
       $name =~ tr/[A-Z]/[a-z]/ ;
       $sub_dir = substr($name,index($name,_)+1,1) ;
       print"$sw_current/$sub_dir/$name\n";
     }
   } else {
     $_.="\n";
     last;
   }
}
exit;
