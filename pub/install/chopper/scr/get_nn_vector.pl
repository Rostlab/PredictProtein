#!/usr/bin/perl -w

#============================================================
# take files containing chain lists, write NN files for input and output vector
#===============================================================

use lib 'DIRLIB';
use Getopt::Long;
use libGenome qw(getIdList %aa2flex %aa_pdb);
use libList;
use libHssp;

$dir_package = 'DIRPACKAGE';
$dir_package .= '/' if ( $dir_package !~ /\/$/ );
$dir_etc = $dir_package.'etc/';
$fileExtraList = $dir_etc.'pdbExtraDomain.list_unique';
$file_in{'opt'} = $dir_etc.'opt_vector';

@aa = qw( A C D E F G H I K L M N P Q R S T V W Y );
@sec = qw( H E L );
@diff_aa = qw(P H D Y V C);	# significant diff aa comp
				# all NN options
@opt_all = qw(seqWin seq profile sec acc acc2 ri_s ri_a relent weight
              seg len endpos secdiff alnend accdiff flex aacomp myent);
	

				# default options
$opt_help = '';
$opt_debug = 0;


$nodeOut = 2;			# two output nodes

$len4secdiff = 50;
$minLen4secdiff = 20;
$maxSecDiff = 30;

$min_exp_acc = 16;
$len4accdiff = 50;
$minLen4accdiff = 20;
$maxAccDiff = 30;

$fileOut_in = "vector_train.in";
$fileOut_out = "vector_train.out";
$filePos = "sample2pos.list";

@in_file_list = qw(hssp pred opt);

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'i=s' => \$fileOut_in,
		   'o=s' => \$fileOut_out,
		   'opt=s' => \$file_in{'opt'},
		   'hssp=s' => \$file_in{'hssp'},
		   'pred=s' => \$file_in{'pred'},
		   'seg=s' => \$file_in{'seg'},
		   'alnEnd=s' => \$file_in{'alnend'},
		   'pos=s' => \$filePos,
		   'nodeOut=i' => \$nodeOut,
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
	"$nameScr: take files containing chain lists, write NN files for input and output vector \n",
	"Usage: $nameScr [options] -i in_file -o out_file \n",
	"  Opt:  -h, --help    print this help\n",
	"        -l <files>    input list file (REQUIRED)\n",
	"        -i <file>     output file for NN input vector(default nn_vector_in)\n",
	"        -o <file>     output file for NN output vector(default nn_vector_out)\n",
	"        --(no)debug    print debug info(default=nodebug)\n";
    exit(1);
}

foreach $in ( @in_file_list ) {
    if ( ! $file_in{$in} or ! -s $file_in{$in} ) {
	print STDERR
	    "$nameScr: file for $in required but not found, exit..\n";
	exit(1);
    }
}

foreach $o ( @opt_all ) {
    $opt{$o} = 0;
}
%opt = &read_opt(\%opt,$file_in{'opt'});
$halfWin = int($opt{'seqWin'}/2);

				# end of option/sanity check

$ctSample = 0;

if ( ! $opt{'end'}  and ! $opt{'discardEnd'} and -s $fileExtraList ) {
    $extraList = &readExtraList($fileExtraList);
}

$file_intmp = $fileOut_in.'.tmp';
$file_outtmp = $fileOut_out.'.tmp';
open (POS,">$filePos") or die "cannot write to $filePos:$!";

				# write input vector file
open (INTMP,">$file_intmp") or die "cannot write to $file_intmp:$!";
$ctNodeIn = $opt{'seqWin'} * 
    ( $opt{'seq'}*20 + $opt{'profile'}*20 + $opt{'sec'}*3 
      + $opt{'acc'} + $opt{'acc2'} + $opt{'ri_a'} + $opt{'ri_s'} 
      + $opt{'relent'} + $opt{'weight'} + $opt{'myent'} );
$ctNodeIn += $opt{'seg'}+4*$opt{'len'} + 8*$opt{'endpos'} + 
    8*$opt{'secdiff'} + 3*$opt{'alnend'} + 4*$opt{'accdiff'} + 
    2*$opt{'flex'} + 6*$opt{'aacomp'};


@options = sort { $a cmp $b } keys %opt;
print INTMP "** INPUT OPTIONS\n";

foreach $o ( @options ) {
    if ( $opt{$o} ) {
	print INTMP "* $o=",$opt{$o},"\n";
    }
}

$id = $file_in{'pred'};
$id =~ s/.*\///g;
$id =~ s/\..*//g;

print INTMP "*\n*\n";
print INTMP "* overall: (A,T25,I8)\n";
printf INTMP "%-22s: %8d\n","NUMIN",$ctNodeIn;
print INTMP "NUMSAMFILE\n";
print INTMP
    "*\n",
    "* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)\n";


				# write output vector file
open (OUTTMP,">$file_outtmp") or die "cannot write to $file_outtmp:$!";


print OUTTMP "* overall: (A,T25,I8)\n";

printf OUTTMP "%-22s: %8d\n","NUMOUT",$nodeOut;
print OUTTMP "NUMSAMFILE\n";
#printf OUTTMP "%-22s: %8d\n","NUMSAMFILE",$ctSample;
print OUTTMP
    "*\n",
    "* samples: count (I8) SPACE 1..NUMOUT (25I6)\n";




($protLen,$data) = &getData($file_in{'pred'});
if ( ! $data ) {
    print STDERR
	"cannot get data from $file_in{'pred'}, skip..\n";
    exit(1);
}

if ( $opt{'profile'} or $opt{'relent'} or $opt{'weight'} or $opt{'aacomp'} ) {
    $profile = &getProfile($file_in{'hssp'});
    if ( ! $profile ) {
	print STDERR
	    "cannot get profile from ",$file{'hssp'},",exit..\n";
	exit(1);
    }
}
 
if ( $opt{'seg'} ) {
    if ( ! -s $file{'seg'} ) {
	print STDERR
	    "cannot get SEG from ",$file{'seg'},", exit..\n";
	exit(1);
    }
    $seg = &getSeg($file{'seg'});
}

if ( $opt{'alnend'} ) {
    if ( ! -s $file{'alnend'} ) {
        print STDERR
            "cannot get ALNEND from ",$file{'alnend'},", exit..\n";
        exit(1);
    }
    ($nalign,$alnend_local,$alnend_global) = &get_alnend($file{'alnend'});
}
    


$len = scalar(@$data) - 1;
if ( $protLen != $len ) {
    print STDERR
	"length conflict for $id: from file=$protLen, count residue=$len\n";
    exit(1);
}


    				# get the begin loop and end loop
if ( ! $opt{'end'} ) {
    $N_end = 1;
    $C_end = $len;
    for $i ( 1..$len ) {
	next if ( ! $data->[$i]{'domain'} );
	$N_end = $i;
	last;
    }
    for ( $i=$len;$i>=1;$i--) {
	next if ( ! $data->[$i]{'domain'} );
	$C_end = $i;
	last;
    }
    if ( $N_end >= $C_end ) {
	print STDERR "No domain defined in $id\n";
	next;
    }
}


if ( defined %$extraList and defined $extraList->{$id}{'C'} ) {
    $extraLenC = $extraList->{$id}{'C'};
} else {
    $extraLenC = 0;
}

if ( defined %$extraList and defined $extraList->{$id}{'N'} ) {
    $extraLenN = $extraList{$id}{'N'};
} else {
    $extraLenN = 0;
}
    
    

if ( $opt{'len'} ) {		# input nodes for protein length
    $fullLen = $len;
    $fullLen += $extraLenC + $extraLenN;
    $vectorLen = &getLenVector($fullLen);
}	

for $i ( 1..$len ) {
    $winBeg = $i - $halfWin;
    $winEnd = $i + $halfWin;
    next if ( $winBeg < 1 or $winEnd > $len );
	
    if ( $opt{'end'} ) {	# all ends as linker
	if ( $data->[$i]{'domain'} ) {
	    $output = 0;
	} else {
	    $output = 100;
	}
    } else {		# only real linker or end with an exrta domain
	if ( $data->[$i]{'domain'} ) {
	    $output = 0;
	} elsif ( $i > $C_end and ! $extraList->{$id}{'C'} ) {
	    #$output = 0;
	    die;		# discard the sample
	} elsif ( $i < $N_end and ! $extraList->{$id}{'N'} ) {
	    die;		# discard the sample
	    #$output = 0;
	} else {
	    $output = 100;
	}
	    
    }	    


				# input vector
    undef @input;
    $sumSeg = 0 if ( $opt{'seg'} );
    $sum_flex = 0 if ( $opt{'flex'} );
    undef %aa_ct;
    for $j ( $winBeg..$winEnd ) {
	# sequence vector
	if ( $opt{'seq'} ) {
	    foreach $aa ( @aa ) {
		if ( $data->[$j]{'aa'} eq $aa ) {
		    push @input, 100;
		} else {
		    push @input, 0;
		}
	    }
	}
	
	if ( $opt{'profile'} ) {
	    foreach $aa ( @aa ) {
		push @input, $profile->{$j}{$aa};
	    }
	}
	if ( $opt{'sec_simple'} ) {
	    foreach $sec ( @sec ) {
		if ( $data->[$j]{'sec'} eq $sec ) {
		    push @input, 100;
		} else {
		    push @input, 0;
		}
	    }
	} elsif ( $opt{'sec'} ) {
	    push 
		@input, $data->[$j]{'sec_H'},
		$data->[$j]{'sec_E'},$data->[$j]{'sec_L'};
	}

	if ( $opt{'acc'} ) {
	    push @input, $data->[$j]{'acc'};
	}
	    
	if ( $opt{'relent'} ) {
	    push @input, $profile->{$j}{'RELENT'};
	}
	if ( $opt{'weight'} ) {
	    $weight = $profile->{$j}{'WEIGHT'};
	    $weight = $weight / 2 * 100; # 2 is the maximum of weight
	    push @input, $weight;
	    #print STDERR "xx weight=",$profile->{$j}{'WEIGHT'},"\n";
	}

	    
				# seg sum
	$sumSeg += $seg->[$j] if ( $opt{'seg'} );
	    			# sum of flexibility
	$sum_flex += $aa2flex{$data->[$j]{'aa'}};

	    			# aa composition of the profile
	if ( $opt{'aacomp'} ) {
	    foreach $aa ( @aa ) {
		$aa_ct{$aa} += $profile->{$j}{$aa};
	    }			
	}
    }


				# alignment ends
    if ( $opt{'alnend'} ) {
	$end_local = $alnend_local->[$i]*10; # scale it up
	$end_global = $alnend_global->[$i]*40; 
	$end_local = 100 if ( $end_local > 100 );
	$end_global = 100 if ( $end_global > 100 );
	if ( $nalign == 0 ) {
	    $end_local_perc = 0;
	} else {
	    $end_local_perc = int($alnend_local->[$i]/$nalign*100);
	}
	push @input, $end_local,$end_local_perc,$end_global;
    }
    
				# seg
    if ( $opt{'seg'} ) {
	$aveSeg = int ( $sumSeg / $opt{'seqWin'} * 100);
	push @input, $aveSeg;
    }
				# length vector
    if ( $opt{'len'} ) {
	push @input, @$vectorLen;
    }

				# position regards to the ends
    if ( $opt{'endpos'} ) {
	$Npos = $i + $extraLenN;
	$Cpos = $len - $i + $extraLenC;
	$vposN = &getPosVec($Npos);
	$vposC = &getPosVec($Cpos);
	push @input, @$vposN;
	push @input, @$vposC;
    }


				# acc difference
    if ( $opt{'accdiff'} ) {
	$perc_exp_N = $perc_exp_C = $diff_exp_N = $diff_exp_C = 0;
	if ( $i > $minLen4accdiff and $len - $i > $minLen4accdiff ) {
	    ($perc_exp_N,$perc_exp_C) = 
		&getAccContent($data,$i,$len,$len4accdiff);
	    if ( $perc_exp_N > $perc_exp_C ) {
		$diff_exp_N = int(($perc_exp_N - $perc_exp_C)/$maxAccDiff*100);
	    } else {
		$diff_exp_C = int(($perc_exp_C - $perc_exp_N)/$maxAccDiff*100);
	    }
	}
	push @input,$perc_exp_N,$perc_exp_C,$diff_exp_N,$diff_exp_C;
    }

    if ( $opt{'secdiff'} ) {
	$perc_H_N = $perc_E_N = $perc_H_C = $perc_E_C = 0;
	$diff_H_N = $diff_E_N = $diff_H_C = $diff_E_C = 0;
	if ( $i > $minLen4secdiff and $len - $i > $minLen4secdiff ) {
	    #print STDERR $i,"\n";die;
	    ($perc_H_N,$perc_E_N,$perc_H_C,$perc_E_C) = 
		&getSecContent($data,$i,$len,$len4secdiff);
	    if ( $perc_H_N > $perc_H_C ) {
		$diff_H_N = int(($perc_H_N - $perc_H_C)/$maxSecDiff*100);
	    } else {
		$diff_H_C = int(($perc_H_C - $perc_H_N)/$maxSecDiff*100);
	    }
	    if ( $perc_E_N > $perc_E_C ) {
		$diff_E_N = int(($perc_E_N - $perc_E_C)/$maxSecDiff*100);
	    } else {
		$diff_E_C = int(($perc_E_C - $perc_E_N)/$maxSecDiff*100);
	    }
	}
	push @input,$perc_H_N,$perc_E_N,$perc_H_C,$perc_E_C;
	push @input,$diff_H_N,$diff_E_N,$diff_H_C,$diff_E_C;
    }

				# flexibility
    if ( $opt{'flex'} ) {
	$ave_flex = int($sum_flex/$opt{'seqWin'});
	$mid_flex = $aa2flex{$data->[$i]{'aa'}};
	push @input, $ave_flex, $mid_flex;
    }
    
				# amino acid composition of the profile
    if ( $opt{"aacomp"} ) {
	$aacomp = &get_aa_comp4(\%aa_ct);
	push @input, @$aacomp;
    }

	#print STDERR "i=$i,beg=$winBeg,end=$winEnd\n",join(',',@input),"\n"; die;
    $ctSample++;
	
				# write input and output vector files
    printf INTMP "%-8s%8d\n","ITSAM:",$ctSample;
    $ctNode = 0;
    foreach $input ( @input ) {
	$ctNode++;
	printf INTMP "%6d",$input;
	if ( $ctNode % 25 == 0 ) {
	    print INTMP "\n";
	}
    }
    print INTMP "\n" if ( $ctNodeIn % 25 != 0 );
    
    if ( $nodeOut == 1 ) {
	printf OUTTMP "%8d%6d\n",$ctSample,$output;
    } elsif ( $nodeOut == 2 ) {
	printf OUTTMP "%8d%6d%6d\n",$ctSample,$output,100-$output;
    } else {
	die "output node should be either 1 or 2, nodeOut=$nodeOut\n";
    }
    print POS "$ctSample\t$id\t$i\n";
}
close POS;

print INTMP "//\n";
close INTMP;

print OUTTMP "//\n";
close OUTTMP;

&replaceCtSample($ctSample,$file_intmp,$fileOut_in);
&replaceCtSample($ctSample,$file_outtmp,$fileOut_out);   


exit;

sub get_aa_comp1 {
    my ( $ct ) = @_;
    my ( $ct_all, $aa, @comp, $comp );

    undef @comp;
    $ct_all = 0;
    foreach $aa ( @aa ) {
	$ct->{$aa} = 0 if ( ! defined $ct->{$aa} );
	#$ct->{$aa} += $aa_pdb{$aa}/2;
	$ct_all += $ct->{$aa};
    }
    foreach $aa ( @aa ) {
	$comp = int($ct->{$aa}/$ct_all*100);
	push @comp, $comp;
    }
    return [@comp];
}

sub get_aa_comp2 {
    my ( $ct ) = @_;
    my ( $ct_all, $aa, @comp, $comp );

    undef @comp;
    $ct_all = 0;
    foreach $aa ( @aa ) {
	$ct->{$aa} = 0 if ( ! defined $ct->{$aa} );
	$ct_all += $ct->{$aa};
    }
    foreach $aa ( @diff_aa ) {
	$comp = int($ct->{$aa}/$ct_all*100);
	push @comp, $comp;
    }
    return [@comp];
}


sub get_aa_comp3 {
    my ( $ct ) = @_;
    my ( $ct_all, $aa, @comp, $comp );

    undef @comp;
    $ct_all = 0;
    foreach $aa ( @aa ) {
	$ct->{$aa} = 0 if ( ! defined $ct->{$aa} );
	$ct->{$aa} += $aa_pdb{$aa}/2;
	$ct_all += $ct->{$aa};
    }
    foreach $aa ( @diff_aa ) {
	$comp = int($ct->{$aa}/$ct_all*100*4);
	$comp = 100 if ($comp > 100);
	push @comp, $comp;
    }
    return [@comp];
}

sub get_aa_comp4 {
    my ( $ct ) = @_;
    my ( $ct_all, $aa, @comp, $comp );

    undef @comp;
    $ct_all = 0;
    foreach $aa ( @aa ) {
	$ct->{$aa} = 0 if ( ! defined $ct->{$aa} );
	#$ct->{$aa} += $aa_pdb{$aa}/2;
	$ct_all += $ct->{$aa};
    }
    foreach $aa ( @diff_aa ) {
	$comp = int($ct->{$aa}/$ct_all*100*4);
	$comp = 100 if ($comp > 100);
	push @comp, $comp;
    }
    return [@comp];
}


sub getAccContent {
    my ( $accData,$pos,$seqLen,$winLen ) = @_;
    my ( $ctRes,$ct_exp,$i,$acc,$perc_exp_N,$perc_exp_C );
    				# N-term
    $ctRes = $ct_exp = 0;
    for ($i=$pos-1;$i>0;$i--) {
	$ctRes++;
	last if ( $ctRes > $winLen );
	$acc=$accData->[$i]{'acc'};
	$ct_exp++ if ( $acc >= $min_exp_acc );
    }
    $perc_exp_N = int($ct_exp/$ctRes*100);

    				# C-term
    $ctRes = $ct_exp = 0;
    for ($i=$pos+1;$i<=$seqLen;$i++) {
	$ctRes++;
	last if ( $ctRes > $winLen );
	$acc=$accData->[$i]{'acc'};
	$ct_exp++ if ( $acc >= $min_exp_acc );
    }
    $perc_exp_C = int($ct_exp/$ctRes*100);

    return ($perc_exp_N,$perc_exp_C);
}


sub get_alnend {
    my ( $fileIn ) = @_;
    my ( $sbr,$fhIn,$pos,$loc,$global,@local_ct,@global_ct,$nalign );
    $sbr = "get_alnend";
    $fhIn = "FH_$sbr";
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while (<$fhIn>) {
	if ( /^\# NALIGN: (\d+)/ ) {
	    $nalign = $1;
	    next;
	}
	next if ( /^\#/ );
	chomp;
	($pos,$loc,$global) = split /\t/;
	$local_ct[$pos] = $loc;
	$global_ct[$pos] = $global;
    }
    close $fhIn;
    return ($nalign,[@local_ct],[@global_ct]);
}


sub getData {
    my ($fileDomain) = @_;
    my $sbr = "getData";
    my ( $fhIn,$lineDomain,@tmpDomain );
    my ( $len,$pos,$aa,$sec,$acc,$domain,@data );

    return undef if ( ! -f $fileDomain or ! -s $fileDomain );
    $fhIn = "DOMAIN_$sbr";
    open ($fhIn,$fileDomain) or die "cannot open $fileDomain:$!";
    undef @data;
    while ( $lineDomain=<$fhIn> ) {
	chomp $lineDomain;
	if ( $lineDomain =~ /^\# LENGTH:\s+(\d+)$/ ) {
	    $len = $1;
	    next;
	}
	next if ( $lineDomain =~ /^(\>|\/\/|\#)/ );
	@tmpDomain = split /\s+/,$lineDomain;
	($pos,$aa,$sec,$sec_H,$sec_E,$sec_L,
	 $acc,$ri_s,$ri_a,$domain) = @tmpDomain[0,2..10];

	#($pos,$aa,$sec,$acc,$ri_s,$ri_a,$domain) = @tmpDomain[0,2..7];

	$data[$pos]{'aa'} = $aa;
	if ( $sec =~ /a|H/i ) {
	    $sec = 'H';
	} elsif ( $sec =~ /b|E/i ) {
	    $sec = 'E';
	} elsif ( $sec =~ /c|L/i ) {
	    $sec = 'L';
	} else {
	    die "$fileDomain\nline:$_\nsec not recognized\n";
	}
	$data[$pos]{'sec'} = $sec;
	$data[$pos]{'sec_H'} = $sec_H * 10;
	$data[$pos]{'sec_E'} = $sec_E * 10;
	$data[$pos]{'sec_L'} = $sec_L * 10;
	$data[$pos]{'acc'} = $acc;
	$data[$pos]{'ri_s'} = $ri_s * 10;
	$data[$pos]{'ri_a'} = $ri_a * 10;
	$data[$pos]{'domain'} = $domain;
    }
    close $fhIn;
    return ($len, [@data]);
}
	

sub getLenVector {
    my ( $length ) = @_;
    my ( @cutoff,$ctCut,$i,@vector );
    @cutoff = qw(0 50 100 200 400);
    $ctCut = scalar @cutoff - 1;
    foreach $i ( 1..$ctCut ) {
	if ( $length <= $cutoff[$i-1] ) {
	    push @vector, 0;
	} elsif ( $length >= $cutoff[$i] ) {
	    push @vector, 100;
	} else {
	    push @vector, int(($length-$cutoff[$i-1])/($cutoff[$i]-$cutoff[$i-1])*100);
	}
    }
    return [@vector];
}


sub getPosVec {
    my ( $pos ) = @_;
    my ( @cutoff,$ctCut,$i,@vector );
    @cutoff = qw(5 10 20 40 60);
    $ctCut = scalar @cutoff ;
    foreach $i ( 0..$ctCut-2 ) {
	if ( $pos <= $cutoff[$i] ) {
	    push @vector, 100;
	} elsif ( $pos > $cutoff[$i+1] ) {
	    push @vector, 0;
	} else {
	    push @vector, int(100-($pos-$cutoff[$i])/($cutoff[$i+1]-$cutoff[$i])*100);
	}
    }
    return [@vector];
}


sub getSecContent {
    my ( $secData,$pos,$seqLen,$winLen ) = @_;
    my ( $ctRes,%ct,$i,$sec,$perc_H_N,$perc_E_N,$perc_H_C,$perc_E_C );
    				# N-term
    $ctRes = 0;
    undef %ct;
    for ($i=$pos-1;$i>0;$i--) {
	$ctRes++;
	last if ( $ctRes > $winLen );
	$sec=$secData->[$i]{'sec'};
	$ct{$sec}++;
    }
    $ct{'H'} = 0 if ( ! defined $ct{'H'} );
    $ct{'E'} = 0 if ( ! defined $ct{'E'} );
    $perc_H_N = int($ct{'H'}/$ctRes*100);
    $perc_E_N = int($ct{'E'}/$ctRes*100);

    				# C-term
    $ctRes = 0;
    undef %ct;
    for ($i=$pos+1;$i<=$seqLen;$i++) {
	$ctRes++;
	last if ( $ctRes > $winLen );
	$sec=$secData->[$i]{'sec'};
	$ct{$sec}++;
    }
    $ct{'H'} = 0 if ( ! defined $ct{'H'} );
    $ct{'E'} = 0 if ( ! defined $ct{'E'} );
    $perc_H_C = int($ct{'H'}/$ctRes*100);
    $perc_E_C = int($ct{'E'}/$ctRes*100);

    return ($perc_H_N,$perc_E_N,$perc_H_C,$perc_E_C);
}


sub getSeg {
    my ( $fileIn ) = @_;
    my ( $sbr,$fhIn,$s,$len,$l,@seg );
    $sbr = "getSeg";
    $fhIn = "FH_$sbr";
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while (<$fhIn>) {
	next if ( /^\>/ );
	chomp;
	s/\s+//g;
	$s .= $_;
    }
    close $fhIn;
    $len = length $s;
    for $i ( 1..$len ) {
	if ( substr($s,$i-1,1) =~ /x/i ) {
	    $seg[$i] = 1;
	} else {
	    $seg[$i] = 0;
	}
    }
    return [@seg];
}


sub readExtraList {
    my ( $fileIn ) = @_;
    my ( $sbr,$fhIn,@tmp,$chain,$ends,@ends,$e,%list );
    $sbr = "readExtraList";
    $fhIn = "IN_$sbr";
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while (<$fhIn>) {
	chomp;
	next if ( /^\#/ );
	next if ( $_ !~ /\w+/ );
	@tmp = split /\t+/;
	($chain,$ends) = @tmp[0,-1];
	$chain =~ s/\(.*//g;
	@ends = split /,/,$ends;
	foreach $e ( @ends ) {
	    ($nc,$lenEnd) = split /\(/,$e;
	    #print "line=$_\nnc=$nc,end=$lenEnd\n";die;
	    $lenEnd =~ s/\)//;
	    $list{$chain}{$nc} = $lenEnd;
	}
    }
    close $fhIn;
    return {%list};
}


sub replaceCtSample {
    my ( $ct,$file_in,$file_out) = @_;
    my $sbr = "replaceCtSample";
    my $fh_in = "IN_$sbr";
    my $fh_out = "OUT_$sbr";

    open ($fh_in,$file_in) or die "cannot open $file_in:$!";
    open ($fh_out,">$file_out") or die "cannot write to $file_out:$!";

    while ($line_in = <$fh_in>) {
	if ( $line_in =~ /^NUMSAMFILE/ ) {
	    printf $fh_out "%-22s: %8d\n","NUMSAMFILE",$ct;
	} else {
	    print $fh_out $line_in;
	}
    }
    close $fh_in;
    close $fh_out;

    if ( (-s $file_out) > (-s $file_in) ) {
	unlink $file_in or die "cannot remove $file_in after editing:$!";
    } else {
	print STDERR "after editing $file_in, output file is smaller\n";
	die;
    }
    return;
}

sub read_opt {
    my ( $opt_ref,$file ) = @_;
    my ($opt_line,@opts,$o,%opt);

    return if ( ! -s $file );

    %opt = %$opt_ref;
    chomp($opt_line = `cat $file`);
    
    $opt_line =~ s/^\s+|\s+$//g;
    @opts = split /\s+/,$opt_line;

    while ($o = shift @opts ) {
	$o =~ s/^-+//g;
	if ( $o eq 'seqWin' ) {
	    $opt{$o} = shift @opts;
	} else {
	    $opt{$o} = 1;
	}
	#print STDERR "$o\t",$opt{$o},"\n";
    }
    #die;
    return %opt;
}
