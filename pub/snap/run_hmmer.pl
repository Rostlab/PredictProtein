#!/usr/bin/perl -w

use lib '/home/liu/pub/lib';
use Getopt::Long;
use libGenome;

$opt_help = '';
$hmm = '/data/pfam/Pfam_ls';

$exe_hmmer = '/usr/pub/molbio/bin/hmmpfam';
$opt_hmmer = " --acc --cpu 1 ";
$ext_out = '.pfam';
$ext_seq = '.fasta';

$Lok = GetOptions ('l=s' => \$file_list,
		   'hmm=s' => \$hmm,
		   'dirSeq=s' => \$dir_seq,
		   'dirOut=s' => \$dir_out,
		   'help'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "Invalid arguments found, -h or --help for help\n";
    exit(1);
}

$nameScr = $0;
$nameScr =~ s/.*\///g;

if ( $opt_help ) {
    &usage();
    exit(1);
}

if ( ! $file_list or ! $dir_seq or ! $dir_out ) {
    &usage();
    exit(1);
}


if ( ! -s $file_list ) {
    print STDERR "*** ERROR: list file $file_list not found, abort..\n";
    &usage();
    exit(1);
}


if ( ! -s $hmm ) {
    print STDERR
	"*** ERROR: HMM db '$hmm' not found, exiting..\n";
    &usage();
    exit(1);
}

if ( ! -d $dir_seq ) {
    print STDERR
	"seq dir '$dir_seq' not found, exiting..\n";
    &usage();
    exit(1);
}
$dir_seq .= '/' if ( $dir_seq !~ /\/$/ );

if ( ! -d $dir_out ) {
    mkdir $dir_out,0755 or die "cannot mkdir $dir_out:$!";
}
if ( ! -w $dir_out ) {
    print STDERR
	"out dir not writable by this UID, abort..\n";
    &usage();
    exit(1);
}
$dir_out .= '/' if ( $dir_out !~ /\/$/ );


$listId = &getIdList($file_list);

foreach $id ( @$listId ) {
    $file_seq = $dir_seq.$id.$ext_seq;
    $file_out = $dir_out.$id.$ext_out;

    if ( ! -s $file_seq ) {
	print STDERR "*** ERROR: $file_seq not found\n";
	next;
    }

    next if ( &isPfam($file_out));
    $cmd = "$exe_hmmer $opt_hmmer $hmm $file_seq > $file_out";
    system $cmd and die "failed to execute $cmd:$!";
    if ( ! -f $file_out ) {	
	print STDERR "after HMMER ($cmd), $file_out not found, abort..\n";
	exit(1);
    }
}

exit;



sub isPfam {
    my ( $filePfam ) = @_;
    return 0 if ( ! -f $filePfam );
    my ( $foundHmm, $foundEnd );
    $foundHmm = $foundEnd = 0;

    open (PFAM, $filePfam) or die "cannot open $filePfam:$!";
    
    while (<PFAM>) {
	$foundHmm = 1 if ( /^HMMER/ );
	$foundEnd = 1 if ( /^\/\// );
    }
    close PFAM;
    return ( $foundHmm and $foundEnd );
}


    
    
	 
sub usage {
    print STDERR
	"$nameScr: run HMMER a list of fasta file\n",
	"Usage: $nameScr [options] -l list -dirSeq seq_dir -dirOut out_dir \n",
	"  Opt:  -h, --help               print this help\n",
	"        -extOut  <string>        output extension(default=$ext_out)\n",
	"        -hmm     <file>          HMM db file(default=$hmm)\n";
}
