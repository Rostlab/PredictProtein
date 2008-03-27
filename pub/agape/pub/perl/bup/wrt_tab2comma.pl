#!/usr/sbin/perl -w

#
# reads file and converts all tabs to commata
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ;	require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";	require "lib-ut.pl"; require "lib-br.pl";

$fhin="FHIN";$fhout="FHOUT";
foreach $arg (@ARGV){
    $file_in=$arg;
    $file_out=$file_in;$file_out=~s/^.*\///g;$file_out=~s/\.[^.]*$/\.prt/g;

    &open_file("$fhin", "$file_in");
    &open_file("$fhout", ">$file_out");
    while (<$fhin>) {
	$_=~s/\t/,/g;
	print $fhout $_;
    }
    close($fhin);close($fhout);
    print "--- output in $file_out\n";
}
exit;
