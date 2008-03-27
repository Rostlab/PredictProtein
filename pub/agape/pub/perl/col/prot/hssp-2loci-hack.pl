#!/usr/sbin/perl -w
#
# finds all HSSP/swiss with 2 loci
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   finds all HSSP/swiss with 2 loci\n";
	      print"usage:  script Merge95-hssp-swiss.rdb\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;

$#loci=$#hssp=$#swiss=$#two=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 $loci=substr($tmp[2],1,3);
		 $hssp=$tmp[5];
		 $swiss=$tmp[6];
		 push(@loci,$loci);push(@hssp,$hssp);push(@swiss,$swiss);}close($fhin);

foreach $it(1..$#hssp){$hssp=$hssp[$it];
		       if (!defined $loci{$hssp}){
			   $loci{$hssp}=$loci[$it];}
		       elsif ($loci{$hssp} ne $loci[$it]) {
			   if (! defined $two{$hssp}){
			       $two{$hssp}=1;
			       print "xx two=$hssp\n";
			       push(@two,$hssp);}}}

&open_file("$fhout", ">$fileOut");
foreach $two(@two){
    print $fhout "$two\n";
}
close($fhout);
print"--- output in '$fileOut'\n";
exit;
