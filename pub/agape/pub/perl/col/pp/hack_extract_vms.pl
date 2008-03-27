#!/usr/pub/bin/perl4 -w
$[ =1 ;

require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";

$title_in=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$file_in="$title_in".".header";
&open_file("$fhin", "$file_in");
while (<$fhin>) {$_=~s/\n//g;
		 $_=~s/^Return.*\<//g;
		 $_=~s/\>$//g;
		 print "$_\n";
		 $tmp=$_; 
		 last ; }close($fhin);
$file_out="pred_e$$";
&open_file("$fhout", ">$file_out");
print $fhout "from $tmp\n";
print $fhout "orig MAIL\n";
print $fhout "resp MAIL\n";
$file_in="$title_in".".text";
&open_file("$fhin", "$file_in");
while (<$fhin>) { print $fhout $_; } close($fhin);
close($fhout);
exit;
