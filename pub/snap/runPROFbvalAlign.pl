#!/usr/local/bin/perl -w
if (@ARGV<3)  {
	die "\nUsage: $0 [*-fil.hssp] [-fil.rdbprof] [results_dir]\n";
	}
$hsspfil=$ARGV[0]; $prof=$ARGV[1];$res=$ARGV[2];
$data=$hsspfil;
if ($hsspfil=~ /(\w+)-fil\.hssp/) {
	$data=$1;
	}
if ($hsspfil=~ /(\w+\.\d+\.)-fil\.hssp/) {
	$data=$1;
	}
$data= "$data.data";
system ("perl ~schles/profbval/createDataFileAlign.pl $hsspfil $prof");
print "\nfinished creating data file\n";
#system ("perl ~schles/profbval/profbval01.pl 9 $data $res");
system ("perl ~schles/profbval/profbval02.pl 9 $data $res");
print ("finished running the netwrok. results are in $res\n");
