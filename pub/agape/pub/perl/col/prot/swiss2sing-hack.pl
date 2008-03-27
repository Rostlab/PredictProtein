#!/usr/sbin/perl -w
#
# another ugly hack: y4-sing and y4-swiss are not identical
# takes y4-swiss and writes y4-sing
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   takes y4-swiss and writes y4-sing\n";
	      print"usage:  script y4-swissExp.rdb (out y4-singExp.rdb)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut=$fileIn; $fileOut=~s/swiss/sing/;

print "-- reading $fileIn\n";
&open_file("$fhin", "$fileIn");
$ct=0;%Lok=0;$#prt=0;
while (<$fhin>) {$_=~s/\n//g;$line=$_;
		 if (/^\#/){
		     push(@prt,$line);}
		 elsif ($ct<3){
		     ++$ct;
		     push(@prt,$line);}
		 else {
		     ++$ct;
		     $_=~s/^[\s\t]|[\s\t]$//;
		     @tmp=split(/\t+/,$_);$tmp[3]=~s/\s//g;$tmp[4]=~s/\s//g;
		     $id="$tmp[3],$tmp[4]";$id1=$tmp[3];
		     if ((! defined $Lok{$id})&&(! defined $Lok{$id1})){
			 push(@prt,$line);
			 print "xx found new $id\n";
			 $Lok{$id}=1;$Lok{$id1}=1;
		     }}
	     }close($fhin);

&open_file("$fhout", ">$fileOut");
foreach $prt (@prt){
    print $fhout "$prt\n";
}
close($fhout);
print "-- output in $fileOut\n";

exit;
