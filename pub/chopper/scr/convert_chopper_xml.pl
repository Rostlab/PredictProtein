#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use lib '/nfs/data5/users/ppuser/server/pub/chopper/scr/lib';
use Getopt::Long;
use libChopper;

				# default options

$opt_debug = 0;
$file_out = '';

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'i=s' => \$file_in,
		   'seq=s' => \$file_seq,
		   'o=s' => \$file_out,
		   'of=s' => \$format_out,
		   'help'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "*** ERROR: Invalid arguments found, -h for help\n";
    &usage();
    exit(1);
}


if ( $opt_help ) {
    &usage();
    exit(1);
}

if ( ! $file_in ) {
    print STDERR
	"*** ERROR: input file not specified\n";
    &usage();
    exit(1);
}

if ( ! -f $file_in ) {
    print STDERR
	"*** ERROR: input file '$file_in' not found, exiting..\n";
    &usage();
    exit(1);
}

if ( ! $format_out ) {
    print STDERR
	"*** ERROR: output format not specified\n\n";
    &usage();
    exit(1);
} 

if ( $format_out eq 'txt' ) {
    &xml2txt_chopper($file_in,$file_out);
} elsif ( $format_out eq 'html' ) {
    &xml2html_chopper($file_in,$file_out);
} elsif ( $format_out eq 'casp' ) {
    if ( ! $file_seq or ! -s $file_seq ) {
	print STDERR 
	    "*** ERROR: sequence file required for CASP output not specified or not found\n";
	exit(1);
    }
    @seq_info = &get_seq_info($file_seq);
    $seq = $seq_info[2];
    if ( ! $seq ) {
	print STDERR
	    "*** ERROR: sequence from $file_seq is empty\n";
	exit(1);
    }
    &xml2casp($file_in,$seq,$file_out);
}



exit;


sub usage {
    $name_scr = $0;
    $name_scr =~ s/.*\///g;

    print STDERR
	"$name_scr: convert CHOPPER xml output to other formats \n",
	"Usage: $name_scr [options] -i in_file \n",
	"  Opt:  -h            print this help\n",
	"        -i <file>     input file (REQUIRED)\n",
	"        -o <file>     output file (default STDOUT)\n",
	"        -of <string>  output format (casp|txt|html)\n",
	"        -seq <file>   sequence file (required for CASP output)\n",
	"        --(no)debug   print debug info(default=nodebug)\n";
}
