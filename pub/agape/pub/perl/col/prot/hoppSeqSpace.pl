#!/usr/sbin/perl -w
#
# hops in sequence space
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$par{"fileHopp"}="/home/rost/pub/data/hssp/hssp792Hopp.rdb";
$fhin="FHIN";$fhout="FHOUT";

if ($#ARGV<1){print"goal:   hops in sequence space\n";
	      print"usage:  script OutDetT-all.dat OutDetF-all.dat (hack  will be HSSP)\n";
	      print"option: fileFamily=    (def=",,"\n";
	      exit;}
				# ------------------------------
				# first read families
$fileIn=$par{"fileHopp"};
if (! -e $fileIn){print"*** no $fileIn (file with HSSP families: id1\tswiss1,swiss2)\n";
		  die;}
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
}
close($fhin);

$fileIn=$ARGV[1];
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
}
close($fhin);

&open_file("$fhout",">$fileOut"); close($fhout);

exit;
