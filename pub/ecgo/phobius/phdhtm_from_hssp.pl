#!/usr/bin/perl

unshift (@INC, "/home/kernytsky/pack/perl/");
require prof;
use Cwd;

foreach (@ARGV) {
    if (/^filelist\=(\S+)/) {
	$filelist_filename = $1;
	open (FL, $filelist_filename) or die "filelist file not found\n";
	while (<FL>) {
 	    chomp;
	    run_phd("/home/kernytsky/work/enzyme/prof/finished/".$_);
	}
    }elsif (/^seqfile\=(\S+)/) {
	$sequence_file = $1;
	$start_cwd = getcwd();
	if ($sequence_file =~ /(.*)\/(.*)/) {
	    chdir ($1); }
	run_phd($2);
	chdir ($start_cwd);
    }
}


#$RESULT = STDOUT;

sub run_phd {
    my $seq_filename = shift;
    
    #$seq_filename =~ m{.*/(.*)\.};
    $seq_filename =~ m{(.*)\.};
    $workfileroot = $1;
    print $workfileroot."\n";
    
    $filename_prof_result = $workfileroot.".rdbPhd";
    $filename_our_result = $workfileroot.".phd_human";
    if (! -e $filename_prof_result) {
	print "### Running PHD\n";
	command ("/home/kernytsky/phd/phd.pl htm ".$seq_filename);
    }
    open ($RESULT, ">$filename_our_result") or die "couldn't open output file $filename_our_result\n";
    if (-e $filename_prof_result) {
	($err, $pred) = prof::extract_preds($filename_prof_result,"PRHL","RI_H");
	if ($err) {
	    #print "$pred\n";
	    ($err, $pred) = prof::extract_preds($filename_prof_result,"PHL","pL","RI_S");
	    if ($err) {die "$pred\n";}
	    $pred =~ s/^.*?\t(1N|1)//mg;
	    
	    #print $RESULT ">$id\n";
	    print $RESULT "RI_S\n";
	    @temp = split /\n/, $pred;
	    $sequence_length = length ($temp[0]);
	    #print "whats being thrown: ".$temp[0]."\n";
	    for ($i=0; $i<$sequence_length; $i++) {print $RESULT "L";}
	    print $RESULT "\n";
	    print $RESULT $temp[1]."\n". $temp[0]."\n";
	    $no_tmh++;
	}else{
	    print $RESULT "RI_H\n";
	    $pred =~ s/^.*?\t(1N|1S|1)//mg;
	    #print $RESULT ">$id\n";
	    #print "$pred";
	    @temp = split /\n/, $pred;
	    print $RESULT $temp[0]."\n".$temp[1]."\n".$temp[0]."\n";
	    $tmh++;
	}
    }else{
	print "### ERROR Could not find PHD result file $filename_prof_result\n";
	#print $RESULT ">$id\n"
	print $RESULT "failed\nphdHTM failed to produce a prediction\n\n\n";
    }
    
}


sub command () {
    my $cmd = shift;
    my $result;

    print "~~ Executing $cmd\n";
    $result = system $cmd;
    print "~~ Execution result => $result\n";
    return $result;
}
