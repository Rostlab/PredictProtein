#!/usr/sbin/perl -w
#
# reads output of statTranslocation, returns statistics about composition
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   reads output of statTranslocation, returns composition statistics\n";
	      print"usage:  statCompoTransl.pl out_statTranslocation (id\tlocation\tSEQWENCE)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";$fhout2="FHOUT2";
$fileOut="Out-transloc.rdb";

$nresMin=10;
$nresMax=40;
$nresItrvl=2;
@aaNamesAbcd= ("A","C","D","E","F","G","H","I","K","L",
	       "M","N","P","Q","R","S","T","V","W","Y");
@desLoci=("nuc","cyt","ext");
foreach $des (@desLoci){	# ini
    $rd{"id","$des"}=$rd{"aa","$des"}="";}
&open_file("$fhin", "$fileIn");	# read file
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t+/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
		 $Lok=0;
		 foreach $loc (@desLoci){
		     if ($tmp[2]=~/^$loc/){$rd{"id","$loc"}.="$tmp[1]".",";
					   $rd{"aa","$loc"}.="$tmp[3]".",";
					   $Lok=1;
					   last;}}
		 if (! $Lok){print "*** missing location for '$_'\n";}} close($fhin);
$nres=$nresMin;
while ($nres <= $nresMax){	# intervals from nresMin .. nresMax (in steps of nresItrvl)
    $fileOutTmp=$fileOut; $fileOutTmp=~s/Out-/Out-$nres-/;
    &open_file("$fhout", ">$fileOutTmp");
    print $fhout "# Perl-RDB\n","# translocation residues 1-$nres\n";
    print $fhout "loci\tid2";	# names
    foreach $aaSym (@aaNamesAbcd){print $fhout "\t$aaSym";}print $fhout "\n";
    print $fhout "15S\t10S";	# formats
    foreach $aaSym (@aaNamesAbcd){print $fhout "\t5.2F";}print $fhout "\n";
	
				# ------------------------------
    foreach $loc (@desLoci){	# statistics
	$rd{"id","$loc"}=~s/,$//g; # purge leading commata
	$rd{"aa","$loc"}=~s/,$//g; # purge leading commata
	@protId=split(/,/,$rd{"id","$loc"});
	@protAa=split(/,/,$rd{"aa","$loc"});
	foreach $it (1..$#protAa){ # all proteins
	    printf $fhout "%-15s\t%-10s",$loc,$protId[$it];

	    $tmp=substr($protAa[$it],1,$nres); # take only nres first residues
	    %res=0;		# compute composition
	    @seq=split(//,$tmp);foreach $aaSym (@aaNamesAbcd){$res{$aaSym}=0;} # ini
	    foreach $aaSym (@aaNamesAbcd){
		foreach $seq (@seq){
		    if ($seq eq $aaSym){
			++$res{$aaSym};}}}
	    foreach $aaSym (@aaNamesAbcd){
		if ($aaSym eq $aaNamesAbcd[$#aaNamesAbcd]){$sep="\n";}else{$sep="\t";}
		printf $fhout "%5.2f$sep",100*$res{$aaSym}/$nres;}}
    }close($fhout);
    $nres+=$nresItrvl;
}				# end of looping over intervals
exit;
