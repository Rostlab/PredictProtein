#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use lib '/nfs/data5/users/ppuser/server/pub/chopper/scr/lib';
use Getopt::Long;
use libGenome;


				# default options
$opt_help = '';
$opt_debug = 0;

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'i=s' => \$fileIn,
		   'o=s' => \$fileOut,
		   'help'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "Invalid arguments found, -h or --help for help\n";
    exit(1);
}

$nameScr = $0;
$nameScr =~ s/.*\///g;

if ( $opt_help ) {
    print STDERR
	"$nameScr: purpose of script \n",
	"Usage: $nameScr [options] -i in_file -o out_file \n",
	"  Opt:  -h, --help    print this help\n",
	"        -i <file>     input file -- file of output vector (REQUIRED)\n",
	"        -o <file>     output file (default STDOUT)\n",
	"        --(no)debug    print debug info(default=nodebug)\n";
    exit(1);
}

if ( ! $fileIn ) {
    print STDERR
	"Usage: $nameScr [options]  -i vector_out_file -n total_number_of_sample -o out_file \n",
	"Try $nameScr --help for more information\n";
    exit(1);
}

if ( ! -f $fileIn  ) {
    print STDERR
	"input file '$fileIn' not found, exiting..\n";
    exit(1);
}

				# end of option/sanity check

$fhOut = 'STDOUT';
if ( $fileOut ) {
    $fhOut = 'OUT';
    open ( $fhOut, ">$fileOut") or die "cannot write to $fileOut:$!";
}


$ctSample = &getCount($fileIn);
				# header
print $fhOut "* overall: (A,T25,I8)\n";
printf $fhOut "%-22s: %8d\n","STPMAX",$ctSample;
print $fhOut
    "* --------------------\n",
    "* positions: (25I8)\n";


foreach $i ( 1..$ctSample ) {
    printf $fhOut "%8d",$i;
    print $fhOut "\n" if ( $i % 25 == 0 );
}
print $fhOut "\n" if ( $ctSample % 25 != 0 );
print $fhOut "//\n";

close $fhOut;

exit;


sub getCount {
    my ( $fileIn ) = @_;
    my ( $ct );
    open (IN,$fileIn) or die "cannot open $fileIn:$!";
    while (<IN>) {
	s/\s+//g;
	next if ( $_ !~ /^NUMSAMFILE:(\d+)$/ );
	$ct = $1;
	last;
    }
    close IN;
    return ($ct);
}
