#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use lib 'DIRLIB';
use Getopt::Long;
use File::Copy;
use Storable;
use libGenome;
use libList qw(mean);
use libChopper;

				# default options
$opt_help = '';
$opt_debug = 0;
$format_out = 'xml';

$dir_report = "./";
$min_linker = 20;

#$smooth_win = 7;
#$smooth_win2 = 7;
#$min_occupancy = 3;
#$pos_rate = 6;

$smooth_win = 11;
$smooth_win2 = 11;
$min_occupancy = 2;
$pos_rate = 8;

$ave_domain_len = 350;
$min_domain_len = 30;
$max_linker_len = 30;
$default_linker_len = 5;

#%max_cut = ( '100' => 50,
#     '200' => 30 );

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'win=i' => \$smooth_win,
		   'win2=i' => \$smooth_win2,
		   'cutoff=i' => \$cutoff,
		   'pos=i' => \$pos_rate,
		   'aveDomain=i' => \$ave_domain_len,
		   'maxLinker=i' => \$max_linker_len,
		   'occu=i' => \$min_occupancy,
		   'i=s' => \$file_in,
		   'o=s' => \$file_out,
		   'of=s' => \$format_out,
		   'id=s' => \$id,
		   'l=i' => \$prot_len,
		   'help'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "*** ERROR: Invalid arguments found, -h for help\n";
    &usage();
    exit(1);
}

$name_scr = $0;
$name_scr =~ s/.*\///g;

if ( $opt_help ) {
    &usage();
    exit(1);
}

if ( ! $file_in  or ! $file_out ) {
    print STDERR "*** ERROR: input or output file not specified\n\n";
    &usage();
    exit(1);
}

if ( ! -s $file_in  ) {
    print STDERR "*** ERROR: input file '$file_in'  not found, exiting..\n";
    &usage();
    exit(1);
}

				# end of option/sanity check


if ( ! $id ) {
    $id = $file_in;
    $id =~ s/.*\///g;
    $id =~ s/\..*//g;
}

$pred_value = &rd_pred($file_in);

if ( ! defined $prot_len ) {
    $prot_len = scalar (@$pred_value);
}

if ( $prot_len < 100 ) {
    $max_cut = 60;
} elsif ( $prot_len < 200 ) {
    $max_cut = 30;
} else {
    $max_cut = 0;
}


$cutoff = &get_cutoff($pred_value,$pos_rate,$max_cut);

$smooth_value1 = &smooth1($pred_value,$smooth_win);
$smooth_value2 = &smooth2($smooth_value1,$cutoff,$smooth_win2,$min_occupancy);
$prune_value = &prune($smooth_value2,$cutoff);
$linkers = &get_domain_stat($prune_value);
$linkers_str = &adjust_domain_len($prot_len,$linkers);
#  &print_smooth($id,$obs_value,$pred_value,$smooth_value1,$smooth_value2,$prune_value);

$protein->{'domains'} = &linker2domain($linkers_str,$prot_len);
$protein->{'proteinID'} = $id;
$protein->{'length'} = $prot_len;

 				# output
if ( $format_out eq 'storable' ) {
    store($protein,$file_out);
} elsif ( $format_out eq 'xml' ) {
    &hash2xml($protein,$file_out);
}

exit;


sub adjust_domain_len {
    my ( $prot_len,$linker_ref) = @_;
    my ( @linker,$equal_linker,$ct_domain,$linker_no_old,$linker_no_new );
    my ( $l,$beg,$end,$prev,$prev_beg,$prev_end,$prev_domain_len );
    my ( $mid_linker_len,$mid_linker_center,$mid_linker_beg,$mid_linker_end,$mid_linker);
    my ( $last_linker,$last_beg,$last_end,$last_domain_len );
    my ( $first_linker,$first_beg,$first_end,$first_domain_len );
    undef @linker;

    if ( $opt_debug ) {
	print STDERR "unadjusted linkers: ",join(',',@$linker_ref),"\n"; 
    }
    if ( ! @$linker_ref ) {	# single domain, check protein length
	#die "here??\n";
	if ( $prot_len <= 2 * $ave_domain_len  ) {
	    return ('NULL');
	} else {
	    $equal_linker = &equal_split(1,$prot_len);
	    push @linker, @$equal_linker;
	    $ct_domain = scalar(@linker) + 1;
	    return ( join(',',@linker) );
	}
    }
		 
	
    				# multi-domain proteins
    $linker_no_old = $linker_no_new = 0;
    foreach $l ( @$linker_ref ) {
	$linker_no_old++;
	($beg,$end) = split /-/, $l;
	$linker_len = $end - $beg + 1;
	if ( $linker_len > $max_linker_len ) {
	    $beg = &pick_best_linker($beg,$end,$max_linker_len);
	    #$old_center = int(($beg+$end)/2);
	    #$beg = $old_center - $default_linker_len;
	    #$end = $old_center + $default_linker_len;
	    $end = $beg + $max_linker_len -1;
	    $old_linker = "$beg-$end";
	    if ( $opt_debug ) {
		print STDERR 
		    "shorten linker $l to $old_linker\n";
	    }
	} else {
	    $old_linker = $l;
	}

				# check the first domain
	if ( $linker_no_new == 0 ) {
	    $first_linker = $old_linker;
	    ($first_beg,$first_end) = split /-/, $first_linker;
	    $first_domain_len = $first_beg - 1;

	    if ( $first_domain_len > 2 * $ave_domain_len ) {
		$equal_linker = &equal_split(1,$first_beg - 1);
		push @linker, @$equal_linker;
	    }

	    if (  $first_domain_len > $min_domain_len ) {
		push @linker,$old_linker;
	    }
	    $linker_no_new = scalar(@linker);
	    next;
	}

#	if ( $linker_no_old == 1 ) {
#	    push @linker,$old_linker;
#	    $linker_no_new++;
#	    next;
#	}

				# compare with the last linker in 'new linkers'
	$prev = $linker[$linker_no_new-1];

	($prev_beg,$prev_end) = split /-/,$prev;
	$prev_domain_len = $beg - $prev_end - 1;
	
				# domain too long, equal split
	if ( $prev_domain_len > 2 * $ave_domain_len ) {
	    $equal_linker = &equal_split($prev_end+1,$beg-1);
	    #if ( $opt_debug ) {
	#	print STDERR
	#	    "spliting  ",$prev_end+1,',',$beg-1,"\n",
	#	    join(',',@$equal_linker),"\n";
	#    }
	    push @linker, @$equal_linker;
	    push @linker, $old_linker;
	    $linker_no_new = scalar(@linker);
	} elsif ( $prev_domain_len < $min_domain_len ) { # too short, combine
	    #$mid_linker_center = int(($beg+$prev_end)/2);
	    $mid_linker_len = int(( $end-$beg+$prev_end-$prev_beg+2 )/2);
	    #$mid_linker_beg = $mid_linker_center - $mid_linker_len;
	    $mid_linker_beg = &pick_best_linker($prev_beg,$end,$mid_linker_len);
	    $mid_linker_end = $mid_linker_beg + $mid_linker_len -1;
	    #$mid_linker_end = $mid_linker_center + $mid_linker_len;
	    $mid_linker = "$mid_linker_beg-$mid_linker_end";

	    pop @linker;
	    push @linker,$mid_linker;
	    if ( $opt_debug ) {
		print STDERR "merge linkers $prev,$l to $mid_linker\n";
	    }
	} else {
	    push @linker,$old_linker;
	    $linker_no_new++;
	}
    }

    #print STDERR "linker_no=$linker_no_new\n";die;
    				# check the last domain
    if ( $linker_no_new > 0 ) {
	$last_linker = $linker[$linker_no_new-1];
	($last_beg,$last_end) = split /-/, $last_linker;
	$last_domain_len = $prot_len - $last_end;
    
	if ( $last_domain_len > 2 * $ave_domain_len ) {
	    $equal_linker = &equal_split($last_end+1,$prot_len);
	    push @linker, @$equal_linker;
	    $linker_no_new = scalar(@linker);
	} elsif ( $last_domain_len < $min_domain_len ) {
	    pop @linker;
	    $linker_no_new--;
	}
    }
    				
    $ct_domain = $linker_no_new + 1;
    if ( $ct_domain == 1 ) {
	return ('NULL');
    } else {
	return (join(',',@linker) );
    }
}


sub equal_split {
    my ( $beg, $end ) = @_;
    my ( $len,$ct_domain,$ave_len,$i,$linker_center,$linker_beg,$linker_end,@linker);

    undef @linker;

    $len = $end - $beg + 1;
    $ct_domain = int($len/$ave_domain_len);
    $ave_len = int($len/$ct_domain);
    for $i ( 1..$ct_domain-1 ) {
	$linker_center = $i * $ave_len + $beg ;
	$linker_beg = $linker_center - $default_linker_len;
	$linker_end = $linker_center + $default_linker_len;
	push @linker, "$linker_beg-$linker_end";
    }
    if ( $opt_debug ) {
	print STDERR "spliting $beg,$end\n",
	join(',',@linker),"\n";
    }
    return ( [@linker] );
}


sub get_domain_stat {
    my ( $list_in ) = @_;
    my (@linkers,$is_in_linker,$list_len,$i,$linker_beg,$linker_end);
    #my ($linkers,$ct_domain);

    undef @linkers;
    $is_in_linker = 0;

    $list_len = scalar (@$list_in);
    for $i ( 1..$list_len-1 ) {	
	next if ( ! defined $list_in->[$i] );
	if ( $list_in->[$i] >= $cutoff ) {
	    if ( ! $is_in_linker ) {
		$linker_beg = $i;
	    }
	    $is_in_linker = 1;
	} else {
	    if ( $is_in_linker ) {
		$linker_end = $i - 1;
		if ( $linker_beg != 1 ) {
		    push @linkers, "$linker_beg-$linker_end";
		}
	    }
	    $is_in_linker = 0;
	}
    }
#    $ct_domain = scalar(@linkers) + 1;
#    if ( @linkers ) {
#	$linkers = join(',',@linkers);
#    } else {
#	$linkers = 'NULL';
#    }
    
#    return ($ct_domain,$linkers);
    return ([@linkers]);
}


sub get_cutoff {
    my ( $list, $pos_rate, $max_cut ) = @_;
    my ( $item,@list2,$ct_item,$ct_pos,$cut);
    
    undef @list2;

    foreach $item ( @$list ) {
	next if ( ! defined $item );
	push @list2,$item;
    }
    @list2 = sort { $b <=> $a } @list2;
    $ct_item = scalar(@list2);
    $ct_pos = $pos_rate*$ct_item/100;
    $cut = $list2[$ct_pos];
    $cut = ( $cut > $max_cut )? $cut: $max_cut;
    $cut += 0.5;
    return $cut;
}


sub linker2domain {
    my ( $linkers,$seq_len ) = @_;
    
    my ( %domain,@linkers,$i,$ct_domain,@domains,@linker_beg,@linker_end );

    undef %domain;
    undef @linkers;
    undef @linker_beg;
    undef @linker_end;

    if ( $linkers eq 'NULL' ) {	# one domain protein
	%domain = ( 'domainRegion' => "1-$seq_len",
		    'source' => 'CHOPnet',
		    );
	return [ {%domain} ];
    }

    @linkers = split /,/,$linkers;
    for $i ( 0..$#linkers ) {
	($linker_beg[$i],$linker_end[$i]) = split /-/, $linkers[$i];
    }

    $ct_domain = scalar(@linkers) + 1;
    for $i ( 1..$ct_domain ) {
	if ( $i == 1 ) {
	    %domain = ( 'domainStart' => 1,
			'domainEnd' => $linker_beg[0]-1,
			'source' => 'CHOPnet',
			);
	    push @domains, {%domain};
	} elsif ( $i == $ct_domain ) {
	    %domain = ( 'domainStart' => $linker_end[$i-2]+1,
			'domainEnd' => $seq_len,
			'source' => 'CHOPnet',
			);
	    push @domains, {%domain};
	} else {
	    %domain = ( 'domainStart' => $linker_end[$i-2]+1,
			'domainEnd' => $linker_beg[$i-1]-1,
			'source' => 'CHOPnet',
			);
	    push @domains, {%domain};
	}
    }

    return [ @domains ];
}



sub print_smooth {
    my ($id,$obs,$pred,$smooth,$smooth2,$prune) = @_;
    
    $file_smooth = $dir_report.$id.'.smooth';
    $len = scalar(@$obs);
    open (SMOOTH,">$file_smooth") or die "cannot write to $file_smooth:$!";
    print SMOOTH "# cutoff=$cutoff\n";
    print SMOOTH "# POS\tObs\tPred\tSmooth1\tSmooth2\tPrune\n";
    for $i (1..$len-1) {
	next if ( ! defined $obs->[$i] );
	if ( ! defined $prune->[$i] ) {
	    print STDERR	
		"$id, pos $i: prune value not found\nobs=",$obs->[$i],"\n";
	    die;
	}
	printf SMOOTH 
	    "%d\t%d\t%d\t%d\t%d\t%d\n",
	    $i,$obs->[$i],
	    $pred->[$i],$smooth->[$i],
	    $smooth2->[$i],$prune->[$i];
    }
    close SMOOTH;
}


sub pick_best_linker {
    my ($beg,$end,$len) = @_;
    my ($max_sum,$linker_beg,$linker_end,$sum,$i,$best_linker_beg);
   
    $max_sum = 0;
    for ($linker_beg=$beg;$end-$linker_beg>=$len-1;$linker_beg++) {
	$linker_end = $linker_beg + $len - 1;
	$sum = 0;
	for $i ( $linker_beg..$linker_end ) {
	    $sum+= $prune_value->[$i];
	}
	if ( $max_sum < $sum ) {
	    $max_sum = $sum;
	    $best_linker_beg = $linker_beg;
	}
    }
    return $best_linker_beg;
}

    
sub prune {
    my ( $list_in,$cutoff ) = @_;
    my ($list_len,$i,@list_out);
   
    undef @list_out;

    
    $list_len = scalar (@$list_in);
    @list_out = @$list_in;
    				# get rid of beginning/trailing 'linker'
    for $i ( 1..$list_len-1) {
	next if ( ! defined $list_out[$i] );
	last if ( $list_out[$i] < $cutoff );
	$list_out[$i] = 0;
    }
    for ($i=$list_len-1;$i>1;$i--) {
	next if ( ! defined $list_out[$i] );
	last if ( $list_out[$i] < $cutoff );
	$list_out[$i] = 0;
    }

    for $i ( 1..$list_len-1 ) {	
	next if ( ! defined $list_out[$i] );
	if ( $i < $min_linker or $i > $list_len-$min_linker) {
	    $list_out[$i] = 0;
	    next;
	}

	if ( $list_out[$i] < $cutoff ) {
	    #$list_out[$i] = 0;
	    next;
	}
	if ( $list_out[$i-1] < $cutoff and
	     $list_out[$i+1] < $cutoff ) {
	    #$list_out[$i] = 0;
	    $list_out[$i] = ($list_out[$i-1]+$list_out[$i+1])/2;
	    next;
	}

	if ( $list_out[$i+1] >= $cutoff and 
	     $list_out[$i-1] >= $cutoff ) {
#	    $list_out[$i] = 100;
	    next;
	}

	if ( $list_out[$i-1] >= $cutoff ) {
	    if ( $list_out[$i-2] < $cutoff ) {
		#$list_out[$i] = 0;
		$list_out[$i]=$list_out[$i-2];
	    } else {
#		$list_out[$i] = 100;
	    }
	} else {
	    if ( $list_out[$i+2] < $cutoff ) {
		#$list_out[$i] = 0;
		$list_out[$i]=$list_out[$i+2];
	    } else {
#		$list_out[$i] = 100;
	    }
	}
    }
    
    return [ @list_out ];

}


sub rd_pred {
    my ( $file_in ) = @_;
    my $sbr = "rd_pred";
    my $fh_in = "IN_$sbr";

    my ($line_in,@tmp,$pos,$pred_value,@pred,@obs);

    undef @obs;
    undef @pred;
    open ($fh_in,$file_in) or die "cannot open $file_in:$!";
    while ($line_in=<$fh_in>) {
	next if ( $line_in =~ /^\#/ );
	next if ( $line_in !~ /\w+/ );
	chomp $line_in;
	@tmp = split /\t/,$line_in;
	($pos,$obs_value,$pred_value) = @tmp[0,1,2];
	$pred[$pos] = $pred_value;
	$obs[$pos] = $obs_value;
    }
    close $fh_in;

    return ([@pred]);
}


sub smooth1 {			# ================================
    				# average over a sequence window
    				# --------------------------------
    my ( $list_in,$window ) = @_;
    my ($half_win,$list_len,$i,@list_out,$sum,$j);
   
    undef @list_out;

    $half_win = int($window/2);
    $list_len = scalar (@$list_in);
    for $i ( 1..$list_len-1 ) {
	next if ( ! defined $list_in->[$i] );
	if ( $i+$half_win >= $list_len or $i-$half_win < 1 or
	     ! defined $list_in->[$i+$half_win] or
	     ! defined $list_in->[$i-$half_win] ) {
	    $list_out[$i] = $list_in->[$i];
	    next;
	}

	$sum = 0;
	for $j ($i-$half_win..$i+$half_win) {
	    if ( ! defined $list_in->[$j] ) {
		print STDERR
		    "window $i, position $j, item not defined.\n";
		die;
	    }
	    $sum += $list_in->[$j];
	}
	#$list_out[$i] = int($sum/$window);
	$list_out[$i] = $sum/$window;
    }

    return [ @list_out ];
}

sub smooth2 {			# ===================================
    				# mark as linker if 3 out of 7 residues
    				# are linkers
    				# -----------------------------------
    my ( $list_in,$cutoff,$window,$min_occupancy ) = @_;
    my ($half_win,$list_len,$i,@list_out,$j,$ct_occupancy);
   
    undef @list_out;

    $half_win = int($window/2);
    $list_len = scalar (@$list_in);
    for $i ( 1..$list_len-1 ) {
	next if ( ! defined $list_in->[$i] );
	if ( ! defined $list_in->[$i+$half_win] or
	     ! defined $list_in->[$i-$half_win] ) {
	    $list_out[$i] = $list_in->[$i];
	    next;
	}

	$ct_occupancy = 0;
	@occupied = ();
	for $j ($i-$half_win..$i+$half_win) {
	    if ( $list_in->[$j] and $list_in->[$j] >= $cutoff ) {
		$ct_occupancy++;
		push @occupied, $list_in->[$j];
	    }
	}
	if ( $ct_occupancy > $min_occupancy ) {
	    $list_out[$i] = &mean(\@occupied);
	    #$list_out[$i+1] = 100; # add more linkers
	} else {
	    $list_out[$i] = $list_in->[$i];
	}
    }

    return [ @list_out ];
}



sub usage {
    $name_scr = $0;
    $name_scr =~ s/.*\///g;

    print STDERR
	"$name_scr: post-processing NN output \n",
	"Usage: $name_scr [options] -i file_in -l prot_len -o file_out \n",
	"  Opt:  -h, --help    print this help\n",
	"        -i <file>     input file (REQUIRED)\n",
	"        -o <file>     output file (REQUIRED)\n",
	"        -l <int>      length of the protein\n",
	"        -(no)debug    print debug info(default=nodebug)\n";
}
