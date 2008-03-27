#!/usr/sbin/perl -w
#
# replace many spaces by tabs (delete non-needed spaces)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   replace many spaces by tabs (delete non-needed spaces\n";
	      print"usage:  script file.rdb \n";
	      exit;}

$fileInRdb=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";$fileOut="Out-".$fileInRdb;

&open_file("$fhin", "$fileInRdb");
&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n//g;
		 $_=~s/^\s+|\s+$//g;
		 $_=~s/\s+/\t/g; # $_=~s/([\t0-9A-Za-z])\s([\t0-9A-Za-z])/$1$2/g;
		 $_=~s/\t+/\t/g;
		 print $fhout "$_\n";}close($fhin);close($fhout);
	     

print"--- output in '$fileOut'\n";
exit;
