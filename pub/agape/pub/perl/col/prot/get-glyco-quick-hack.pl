#!/usr/sbin/perl -w
#
# finds SWISS with 'KW GLYCOPROTEIN'
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   finds SWISS with 'KW GLYCOPROTEIN'\n";
	      print"usage:  script list-with-swiss\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhin2="FHIN2";$fhout="FHOUT";
$fileOut="Out-glyc".$fileIn;

$#file=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\s//g;
		 if (! -e $_){next;}
		 $fileSwiss=$_;
		 &open_file("$fhin2", "$fileSwiss");
		 while (<$fhin2>) {if ($_ !~ /^KW/){next;}
				   if ($_ =~ /GLYCOPROTEIN/){
				       print "--- glycoprotein $fileSwiss\n";
				       push(@file,$fileSwiss);}
				   last;}close($fhin2);}close($fhin);
&open_file("$fhout", ">$fileOut");
foreach $file(@file){
    print $fhout "$file\n";
}
close($fhout);
print"--- output in '$fileOut'\n";
exit;
