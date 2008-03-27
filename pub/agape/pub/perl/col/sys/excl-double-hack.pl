#!/usr/sbin/perl -w
#
# excludes double id's from RDB
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   excludes id's from RDB\n";
	      print"usage:  script file.rdb file_with_sw-ids\n";
	      exit;}

$fileInRdb=$ARGV[1];
$fhin="FHIN";
$fhout="FHOUT";
$fileOut="Out-".$fileInRdb;

$#rdb=0;
&open_file("$fhin", "$fileInRdb");
while (<$fhin>) {$line=$_;
		 if ($line !~ /^\#/ ){@tmp=split(/\t/,$line);
				      $id1=$tmp[3];$id2=$tmp[4];
				      if (! defined $ok{"$id1","$id2"}){
					  $ok{"$id1","$id2"}=1;
					  push(@rdb,$_);}
				      else {
					  print "--- excluded id1=$id1, id2=$id2,\n";}
				  }}close($fhin);

&open_file("$fhout", ">$fileOut");
foreach $rdb(@rdb){
    print $fhout $rdb;
}
close($fhout);
print"--- output in '$fileOut'\n";
exit;
