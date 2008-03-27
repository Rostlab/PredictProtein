#!/usr/bin/perl -w
#
# remove strange files
#
$[ =1 ;

if ($#ARGV<1){print"goal:   rmove strange files\n";
	      print"usage:  script file\n";
	      exit;}

$fileIn=$ARGV[1];
system("\\rm $fileIn");
exit;
