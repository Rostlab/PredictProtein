#!/usr/sbin/perl -w

#
# reads file and converts ARG2 to ARG3
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ;	require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";	
require "lib-ut.pl"; require "lib-br.pl";

$file_in=$ARGV[1];
$exp_old=$ARGV[2];$exp_old=~s/\'//g;
$exp_new=$ARGV[3];$exp_new=~s/\'//g;
print "replace old ='$exp_old' by new='$exp_new', for file $file_in\n";

$fhin="FHIN";$fhout="FHOUT";
$file_out=$file_in;$file_out=~s/^.*\///g;$file_out.="_prt";

&open_file("$fhin", "$file_in");
&open_file("$fhout", ">$file_out");
while (<$fhin>) {
    $_=~s/$exp_old/$exp_new/g;
    print $fhout $_;
}
close($fhin);close($fhout);
print "--- output in $file_out\n";
exit;
