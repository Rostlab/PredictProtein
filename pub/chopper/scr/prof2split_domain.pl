#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use Getopt::Long;
use lib '/nfs/data5/users/ppuser/server/pub/chopper/scr/lib';
use libPHD;

				# default options
$opt_help = '';
$opt_debug = 0;

@phdField = qw( No AA PHEL RI_S pH pE pL PREL RI_A );


$Lok = GetOptions ('debug!' => \$opt_debug,
		   'i=s' => \$file_in,
		   'o=s' => \$file_out,
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
	"        -l <file>     list file (REQUIRED)\n",
	"        --(no)debug    print debug info(default=nodebug)\n";
    exit(1);
}

if ( ! $file_in ) {
    print STDERR
	"Usage: $nameScr [options]  -i in_file \n",
	"Try $nameScr --help for more information\n";
    exit(1);
}

if ( ! -s $file_in ) {
    print STDERR
	"input file '$file_in' not found, exiting..\n";
    exit(1);
}

				# end of option/sanity check

$fh_out = 'STDOUT';
if ( $file_out ) {
    if ( $file_out eq $file_in ) {
        print STDERR "$file_out is the same as input file $file_in, abort..\n";
        exit(1);
    }
    $fh_out = 'OUT';
    open ( $fh_out, ">$file_out") or die "cannot write to $file_out:$!";
}


($Lok,$phdData,$errMsg) = &getFieldPHD($file_in,\@phdField);
if ( ! $Lok or ! $phdData ) {
    print STDERR
	"cannot get PHD data from $file_in, msg=$errMsg, skip..\n";
    exit(1);
}


$id = $file_in;
$id =~ s/.*\///g;
$id =~ s/\..*//g;
$len = scalar( keys %$phdData );

print $fh_out 
    "# ID: $id\n",
    "# LENGTH: $len\n",
    "# No\tPDBNo\tSEQ\tSEC\tH\tE\tL\tACC\tRI_S\tRI_A\tDOM\n";

				# 

for $i ( 1..$len ) {
				# error checking
    if ( ! defined $phdData->{$i}{'AA'} or
	 ! defined $phdData->{$i}{'PHEL'} or
	 ! defined $phdData->{$i}{'PREL'} or 
	 ! defined $phdData->{$i}{'RI_S'} or
	 ! defined $phdData->{$i}{'RI_A'} ) {
	print STDERR 
	    "position $i in $file_in: values in PHD not defined\n";
	die;
    }
	
				# writing
    print $fh_out
	$i,"\t",
	$phdData->{$i}{'No'},"\t",
	$phdData->{$i}{'AA'},"\t",
	$phdData->{$i}{'PHEL'},"\t",
	$phdData->{$i}{'pH'},"\t",
	$phdData->{$i}{'pE'},"\t",
	$phdData->{$i}{'pL'},"\t",
	$phdData->{$i}{'PREL'},"\t",
	$phdData->{$i}{'RI_S'},"\t",
	$phdData->{$i}{'RI_A'},"\t",
	"\n";
}
print $fh_out "//\n";
close $fh_out;
	
exit;


