#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use Getopt::Long;

				# default options
$opt_help = '';
$opt_debug = 0;
$smooth_win = 3;

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'pred=s' => \$file_pred,
		   'obs=s' => \$file_obs,
		   'pos=s' => \$file_pos,
		   'win=i' => \$smooth_win,
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
	"        -i <file>     input file (REQUIRED)\n",
	"        -o <file>     output file (default STDOUT)\n",
	"        --(n)debug    print debug info(default=nodebug)\n";
    exit(1);
}

if ( ! $file_pred or ! $file_obs or ! $file_pos ) {
    print STDERR
	"Usage: $nameScr [options]  -pred nn_output -obs vector_out_file -pos position_file -o out_file \n",
	"Try $nameScr --help for more information\n";
    exit(1);
}

if ( ! -f $file_pred or ! -f $file_obs or ! -f $file_pos ) {
    print STDERR
	"input file '$file_pred' or '$file_obs' or '$file_pos' not found, exiting..\n";
    exit(1);
}

				# end of option/sanity check

$fhOut = 'STDOUT';
if ( $file_out ) {
    $fhOut = 'OUT';
    open ( $fhOut, ">$file_out") or die "cannot write to $file_out:$!";
}


$sam2pos = &rdPos($file_pos);
$pred = &rdPred($file_pred);
#$predSmooth = &smooth($pred,$smooth_win);
$obs = &rdObs($file_obs);

@sample = sort { $a <=> $b } keys %$sam2pos;
foreach $s ( @sample ) {
    $pos = $sam2pos->{$s};
    if ( ! defined $pred->[$s] ) {
	print STDERR 
	    "prediction for sample $s not defined, skip..";
	next;
    }
    $prediction = $pred->[$s];

    if ( ! defined $obs->[$s] ) {
	print STDERR 
	    "observation for sample $s not defined, skip..";
	next;
    }
    $observation = $obs->[$s];

#    if ( defined $predSmooth->[$s] ) {
#	$smooth = $predSmooth->[$s];
#    } else {
#	$smooth = "";
#    }
#    print $fhOut "$pos\t$observation\t$prediction\t$smooth\n";
    print $fhOut "$pos\t$observation\t$prediction\n";
}
close $fhOut;


exit;


sub rdObs {
    my ( $file ) = @_;
    my $sbr = "rdObs";
    my $fh = "FH_$sbr";
    my ( $sam,$value,@list );

    undef @list;
    open ($fh,$file) or die "cannot open $file:$!";
    while (<$fh>) {
	next if ( /^\#/ );
	next if ( $_ !~ /\w+/ );
	if (  /^\s*(\d+)\s+(\d+)\s+\d+\s*$/ ) {
	    ($sam,$value) = ($1,$2);
	    $list[$sam] = $value;
	}
    }
    close $fh;
    return [ @list ];
}

sub rdPos {
    my ( $file ) = @_;
    my $sbr = "rdPos";
    my $fh = "FH_$sbr";
    my ( @tmp,$sam,$pos, %hash);

    undef %hash;
    open ($fh,$file) or die "cannot open $file:$!";
    while (<$fh>) {
	next if ( /^\#/ );
	next if ( $_ !~ /\w+/ );
	chomp;
	@tmp = split /\t/;
	($sam,$pos) = @tmp[0,2];
	$hash{$sam} = $pos;
    }
    close $fh;
    return { %hash };
}


sub rdPred {
    my ( $file ) = @_;
    my $sbr = "rdPred";
    my $fh = "FH_$sbr";
    my ( $sam,$value1,$value2,$maxValue,$value,@list );

    undef @list;
    open ($fh,$file) or die "cannot open $file:$!";
    while (<$fh>) {
	next if ( /^\#/ );
	next if ( $_ !~ /\w+/ );
	if (  /^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/ ) {
	    ($sam,$value1,$value2) = ($1,$2,$3);
	    			# normalization
	    if ( $value1 > $value2 ) {
		$maxValue = $value1;
	    } else {
		$maxValue = $value2;
	    }
	    $value = int(50 * ( 1 + ($value1-$value2)/$maxValue));
	    $list[$sam] = $value;
	}
    }
    close $fh;
    return [@list];
}


sub smooth {
    my ( $listRef,$win ) = @_;
    my ( @list,$max,$half_win,$i,$ct,$sum,$j,@out );

    @list = @$listRef;
    $max = $#list;
    $half_win = int($win/2);
    
    for $i ( 1..$max ) {
	$ct = 0;
	$sum = 0;
	for $j ( $i-$half_win..$i+$half_win ) {
	    next if ( $j < 1 or $j > $max );
	    $ct++;
	    $sum += $list[$j];
	}
	$out[$i] = int($sum/$ct);
    }

    return [ @out ];
}
    
