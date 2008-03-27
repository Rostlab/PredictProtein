#!/usr/bin/perl

unshift (@INC, "/home/kernytsky/pack/");
require prof;

$result_filename = "glob_600.phdHTM";
open (RESULT, ">$result_filename") or die "### ERROR Could not open result file $result_filename\n";

$homedir = "/home/kernytsky/work/enzyme/phobius/glob_600";
#$homedir = "/home/kernytsky/phobius/glob_600";
opendir HOME, $homedir or die "error changing to prof\n";
@files = grep /.*\.hssp/, readdir HOME;

$no_tmh=0; $tmh=0;
foreach $filename (@files) {
    #$filename = $homedir."/".$filename;
    #$cmd = "/usr/pub/molbio/phd/phd.pl htm $filename";
    $cmd = "~/phd/phd.pl htm $homedir/$filename";
    #$cmd = "~ppuser/server/pub/phd/phd.pl htm $homedir/$filename";
    #print "$cmd\n";
    #system ($cmd);

    @temp = split /\./, $filename;
    $filename_root = $temp[0];
    $filename_prof_result = $filename_root.".rdbPhd";
    if (-e $filename_prof_result) {
	($err, $pred) = prof::extract_preds($filename_prof_result,"PRHL","RI_H");
	if ($err) {
	    print "$pred\n";
	    ($err, $pred) = prof::extract_preds($filename_prof_result,"PHL","RI_S");
	    if ($err) {die "$pred\n";}
	    print RESULT ">$filename_root\n";
	    chomp $pred;
	    for ($i=0; $i<(length $pred); $i++) {print RESULT "L";}
	    for ($i=0; $i<(length $pred); $i++) {print RESULT "9";}
	    print RESULT "\n\n";
	    $no_tmh++;
	}else{
	    $pred =~ s/^.*?\t(1N|1)//mg;
	    print RESULT ">$filename_root\n$pred";
	    $tmh++;
	}
    }else{
	print "### $filename_prof_result does not exist\n";
    }
    #die;
}

print "Total:   ".($tmh+$no_tmh)."\n";
print "TMH:     $tmh\n";
print "non-TMH: $no_tmh\n";
