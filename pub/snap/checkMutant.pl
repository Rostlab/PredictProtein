#!/usr/bin/perl -w

#this script will check whether the guven mutant is possible in this sequence
# the inputs are 1: sequence file; 2: mutant file
$seq = $ARGV[0];
$mut = $ARGV[1];

open (IN, $seq) || die "Can't open $seq\n";
@seq = <IN>;
$seq = "@seq";
$seq =~ s/\>.+\n//;
$seq =~ s/[^A-Z]//g;
$seq =~ s/(\w)/$1 /g;
@seq = split (/ /, $seq);
close IN;

open (IN, $mut) || die "Can't open $mut\n";
@mut = <IN>;
close IN;
$mut = "@mut";
$mut =~ s/[^a-zA-Z0-9]/\n/g;
@mut = split (/\n/,$mut);
foreach $mut (@mut){
	if ($mut =~ /([A-Z])(\d+)([A-Z])/){
		$org = $1;
		$pos = $2;
		$sub = $3;
		$ar_org = $pos-1;
		if ($seq[$ar_org] eq $org){
			if (!($seq[$ar_org] eq $sub)){
				print "$mut ok\n";
				next;
			}
			else{
				print "Sub $sub is the original residue $org\n";
				die;
			}
		}
		else{
			print "Residues in position $pos is ".$seq[$ar_org]." and NOT $org\n";
		}
	}
}
