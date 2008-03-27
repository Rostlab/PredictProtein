#!/usr/bin/perl

# Modifications 12/3/04 to make this script:
# - get PHD results
# - process file with all fasta sequences in the file rather than 
#   filenames of sequence

# Darek's script modified:
# 1. making ~rost = to ~/rost so it will run on c2b2 
# 2. working through entire script one file at a time, and cleaning up files aftrewards 

# $basedir = "/home/kernytsky/enzyme/prof/kaz_allos/";
#Basedir is now defined by extracting the path of $file1

unshift (@INC, "/home/kernytsky/pack/");
require prof;

use Cwd;
use File::Copy;

# $dir = getcwd();
$sge_task_id = $ENV{"SGE_TASK_ID"};
# $sge_task_id = 1;
print "SGE_TASK_ID = $sge_task_id\n";

# To open list of files
## $file1 = $ARGV[0];  #fasta.list must contain full path name.
## if ($file1 eq "") {die "Usage $0 fasta_list_file\n";}
## open (FHFILE1, $file1) or  die "Error, could not open file1 $file1\n";

# To open file with all sequences
$seq_filename = $ARGV[0];
$result_filename = $seq_filename.".phdHTM";

open (SEQS, $seq_filename) or die "### ERROR Could not open sequence file $seq_filename\n";
open (RESULT, ">$result_filename") or die "### ERROR Could not open result file $result_filename\n";

# Set working directory
# $basedir = "/home/kernytsky/work/enzyme/prof";
$basedir = getcwd();
print "### basedir is $basedir\n";

# $resultpath = $basedir."/work.$sge_task_id/result/";
if ((!defined $sge_task_id) || ($sge_task_id eq "undefined")) { 
    $workpath = $basedir."/work_".$seq_filename;
    if ($workpath eq "") { $workpath = cwd(); }
    print "### No SGE_TASK_ID given, will work in directory $workpath\n"; 
}else{
    $workpath = $basedir."/work.$sge_task_id";
    print "### Will work in directory $workpath\n";
}

# Check if $workpath exists.  If not create it.
if (! -e $workpath) {
    print "### Making directory $workpath\n";
    mkdir $workpath or die;
}
chdir $workpath or die;

$iter=-1;
while (<SEQS>) {
    #Make file vars

    chomp;
    if (/^\#/) {next;}
    if (/^>(.*)/) {
	$iter++;
	$id = $1;
	$_ = <SEQS>;
	chomp;
	$seq = $_;
	$last_seq = 1; # is true if while loop finished because of EOF
	while (<SEQS>) {
	    chomp;
	    if (/^>/) {
		$last_line = $_;
		$last_seq = 0;
		last;
	    }else{
		$seq .= $_;
	    }
	}

	# Write sequence to file
	$workfileroot = "temp".$iter;
	#$workfileroot = $id;
	$seq =~ s/^\s*//;
	$seq =~ s/\#.*$//;
	open SEQ_TEMP, ">$workfileroot.f" or die "could not create temp file\n";
	print SEQ_TEMP ">$id\n$seq\n";
	close SEQ_TEMP;
	$sequence_length = length ($seq);
	#$iter++; redo;

	# Run the PHD process
	&process_seq ($workfileroot, $id);

	# Put the results into the output file
	$filename_prof_result = $workfileroot."-fil.rdbPhd";
	if (-e $filename_prof_result) {
	    ($err, $pred) = prof::extract_preds($filename_prof_result,"PRHL","RI_H");
	    if ($err) {
		print "$pred\n";
		($err, $pred) = prof::extract_preds($filename_prof_result,"PHL","pL","RI_S");
		if ($err) {die "$pred\n";}
		$pred =~ s/^.*?\t(1N|1)//mg;

		print RESULT ">$id\n";
		for ($i=0; $i<$sequence_length; $i++) {print RESULT "L";}
		print RESULT "\n";
		@temp = split /\n/, $pred;
		print RESULT $temp[1]."\n";
		$no_tmh++;
	    }else{
		$pred =~ s/^.*?\t(1N|1)//mg;
		print RESULT ">$id\n$pred";
		$tmh++;
	    }
	}else{
	    print "### ERROR Could not find PHD result file $file\n";
	    print RESULT ">$id\nphdHTM failed to produce a prediction\n\n";
	}
	#$file = $workfileroot."-fil.rdbPhd";
	#if (-e $file) {
	#    $pred = prof::extract_preds($file,"PHL","RI_S");
	#    #print "$pred\n";
	#    $pred =~ s/^.*?\t(1N|1)//mg;
	#    print "$pred\n";
	#    print RESULT ">$id\n$pred";
	#}else{
	#    print "### ERROR Could not find PHD result file $file\n";
	#    print RESULT ">$id\nphdHTM failed to produce a prediction\n\n";
	#}
	$_ = $last_line;
	if ($last_seq) {last;}
	redo;
    }
}

sub process_seq
{
    my ($workfileroot, $id) = @_;

#goto LATER;
    #Check if already done
    if ( -e "$workfileroot-fil.rdbPhd" ) { 
	print "### Skipping file $workfileroot-fil.rdbPhd since it exists\n";
	return; 
    }
    print "\n### Starting work on $workfileroot with goal of creating file:\n###   $workfileroot-fil.rdbPhd\n";

    #print "### Copying fasta file to work directory\n";
    #copy ($filename, $workfileroot.".f") or
    #print "\nXXX ERROR XXX Couldn't move fasta file to result directory\n\n";

    print "### Checking for BLAST resultt\n";
    if ( -e "$workfileroot.blastpgp" ) { 
	print "### BLAST result found, skipping PSI-BLAST\n";	
    }else{
	if ( -e "/work/enzyme/prof/finished/$id-fil.blastpgp") {
	    print "### BLAST result found in prof/finished, skipping PSI-BLAST\n";	
	    system ("cp /work/enzyme/prof/finished/$id-fil.blastpgp $workfileroot.blastpgp");
	}else{
	    print "### Blasting\n";
	    ###command ("/home/kernytsky/pub/molbio/perl/blastpgp.pl $filename");
	    command ("/usr/pub/molbio/perl/blastpgp.pl $workfileroot.f saf maxAli=3000 eSaf=1");
	}
    }
    #print "### Checking the BLAST result file\n";
    #if (1) {
    #if (command ("grep \"\* No hits found \*\" $workfileroot.blastpgp") != 0) {
    #if ($result != 0) {
	#print "### Blasting OK\n";

    ## SAF conversion ##

    $maxAlis = [3000,1000,400];
    $i=0;
    do {
	$maxAli = $maxAlis[$i];
	print "### Converting to SAF format\n";
	command ("/usr/pub/molbio/prof/scr/blast2saf.pl $workfileroot.blastpgp maxAli=$maxAli eSaf=1 red=80");
	print "### Converting to HSSP format\n";
	command ("/usr/pub/molbio/prof/scr/copf.pl exeConvertSeq=/usr/pub/molbio/prof/bin/convert_seq_big.LINUX $workfileroot.saf hssp");
	$i++;
    } while (! -e $workfileroot.".hssp");

    print "### Filtering HSSP file\n";
    command ("/usr/pub/molbio/prof/scr/hssp_filter.pl exe=/usr/pub/molbio/prof/bin/filter_hssp_big.LINUX $workfileroot.hssp red=80");

    print "### Running PHD\n";
    #command ("/usr/pub/molbio/prof/prof ".$workfileroot."-fil.hssp");
    #command ("/usr/pub/molbio/phd/phd.pl htm notHtmtop ".$workfileroot."-fil.hssp");
    command ("/home/kernytsky/phd/phd.pl htm ".$workfileroot."-fil.hssp");

    #system ("rm -f $dir/*.blastpgp");
    #system ("rm -f $dir/*.saf");
    #system ("rm -f $dir/*.tmp");
    #system ("rm -f $dir/*.tmp*");
    #system ("rm -f $dir/*.check*");

    print "### DONE work on $workfileroot?!\n";
}

sub command () {
    my $cmd = shift;
    my $result;

    print "~~ Executing $cmd\n";
    $result = system $cmd;
    print "~~ Execution result => $result\n";
    return $result;
}
