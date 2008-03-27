package      libHssp;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(getProfile getEntropy getAaFreq getStat getQueryLength);
@EXPORT_OK = qw(hsspDist);


#=================================================================
# calculate entropy from HSSP file
#=================================================================



sub getEntropy {
    my ( $fileHssp,$freq_bg, $aa_letter ) = @_;
    my ( $dots, $nAlign, $seqLen, $posAA, $posNOCC, $posAlign, @aa, @alignment );
    my ( $line, @nocc, @entropy,$max_ent, @normalized_ent );

    my $sbr = "getEntropy";
    my $fh = "HSSP_$sbr";
    
    $dots = '....:';

    undef @aa;
    undef @alignment;
    undef @nocc;
    undef @entropy;

    #print "HSSP=$fileHssp\n";
    open ( $fh, $fileHssp ) or die "cannot open $fileHssp:$!";
    while ($line=<$fh> ) {
	last if ( $line =~ /^\#\#\s*ALIGNMENTS/ );
	if ( $line=~ /^NALIGN\s+(\d+)/ ) {
	    $nAlign = $1;
	} elsif ( $line=~ /^SEQLENGTH\s+(\d+)/ ) {
	    $seqLen = $1;
	} else {
	    next;
	}
    }

    while ( $line=<$fh> ) {
	last if ( $line=~/^\#\#\s*SEQUENCE PROFILE/ );
	chomp $line;
	if ( $line=~/\s*SeqNo/ ) {		# header, figure out positions
	    $posAA = index ($line, 'AA');
	    $posAlign = index($line, $dots);
	    $posNOCC = index($line, 'NOCC');
	    next;
	}
	
	if ( $line=~/^\s*(\d+)\s*/ ) {	# alignment block
	    $seqNo = $1;
	    $aa[$seqNo] = substr($line, $posAA, 1);
	    if ( length $line < $posAlign ) {
		$alignment[$seqNo] = "";
	    } else {
		$alignment[$seqNo] .= substr($line,$posAlign,70);
	    }

	    $nocc[$seqNo] = substr($line,$posNOCC,4);
	}
    }
    close $fh;

    $max_ent = 0;
    for $i (1..$seqLen) {
	$entropy[$i] = &calcEntropy($nAlign,$nocc[$i],$alignment[$i],$freq_bg,$aa_letter);
	$max_ent = $entropy[$i] if ( $max_ent < $entropy[$i] );
    }
    
    for $i ( 1..$seqLen ) {
	$normalized_ent[$i] = int($entropy[$i]/$max_ent*100);
    }
    #return ( [ @nocc ], [ @entropy ] );
    return ([@entropy], [@normalized_ent]);
}



sub calcEntropy {
    my ( $nAlign, $nocc, $alignment,$freq_bg,$aa_letter ) = @_;
    my (@seq, $s, %ct, $entropy, $freq, $ctGap );
 
    $ctGap = $nAlign + 1 - $nocc;
    @seq = split //,$alignment;
    foreach $s ( @seq ) {
	$ct{$s}++;
    }

    $entropy = 0;
    foreach $aa ( @$aa_letter ) {
	next if ( ! defined $ct{$aa} or $ct{$aa} == 0 );
	$freq = $ct{$aa} / $nAlign;
	$entropy += $freq * log($freq/$freq_bg->{$aa})/log(2);
    }

				# add entropy to each gap position

    if ( $ctGap ) {
	$entropy += $ctGap/$nAlign *  log($ctGap/$nAlign)/log(2);
    }

    $entropy = (-1) * $entropy;
    print STDERR "$nAlign, $nocc,gap=$ctGap, $alignment,ent=$entropy\n";
    #$entropy =~ s/^\-//;
    return $entropy;
   
}

sub getAaFreq {
    my ($fileIn) = @_;
    my ($sum,@tmp,%f);
    my $sbr = "getAaFreq";
    my $fh = "IN_$sbr";

    $sum = 0;
    open ($fh, $fileIn) or die "cannot open frequency input file $fileIn:$!";
    while ( $line=<$fh> ) {
	next if ( $line=~ /^\s*\#/ );
	chomp $line;
	@tmp = split /\t+/,$line;
	$f{$tmp[0]} = $tmp[2];
	$sum += $tmp[2];
    }
    close $fh;
    return {%f};
}


sub getQueryLength {
    my ( $fileHssp ) = @_;
    my $sbr = "getQueryLength";
    my $fh = "HSSP_$sbr";
    
    my ( $line,$seqLen );

    return undef if (! -s $fileHssp );
    
    undef $seqLen;

    open ( $fh, $fileHssp ) or die "cannot open $fileHssp:$!";
    while ($line=<$fh> ) {
	last if ( $line =~ /^\#\#\s*ALIGNMENTS/ );
	if ( $line=~ /^SEQLENGTH\s+(\d+)/ ) {
	    $seqLen = $1;
	    last;
	} 
    }
    return $seqLen;
}



sub getStat {
    my ( $fileIn ) = @_;
    my $sbr = "getHits";
    my $fhIn = "IN_$sbr";
    my ( $line,$tmpLine,@tmpLine,@fields,%homo,$f,@homos );
    return undef if ( ! -r $fileIn or ! -s $fileIn );

    @fields = qw(id pide psim gap lali lseq2);
    undef @homos;
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while ($line=<$fhIn>) {
	next if ( $line !~ /^\#\# PROTEINS :/ );
	last;
    }
    while ($line=<$fhIn>) {
	last if ($line=~ /^\#\#/ );	# insertion section
	last if ( $line=~/^\/\// ); # end of HSSP file

	next if ( $line !~ /^\s*\d+/ );
	$tmpLine = $line;

	$homo{'id'} = substr($tmpLine,7,12);
	$homo{'pide'} = substr($tmpLine,28,4);
	$homo{'psim'} = substr($tmpLine,33,5);
	$homo{'gap'} =  substr($tmpLine,64,4);
	$homo{'lali'} = substr($tmpLine,59,4);
	$homo{'lseq2'} = substr($tmpLine,74,5);

	foreach $f ( @fields ) {
	    $homo{$f} =~ s/\s+//g;
	}
	$homo{'pide'} = 100 * $homo{'pide'};
	$homo{'psim'} = 100 * $homo{'psim'};
	
	push @homos,{%homo};
    }
    close $fhIn;
    return [@homos];	
}				


sub getProfile {
    my ( $fileIn ) = @_;
    my $sbr = "getProfile";
    my $fhIn = "IN_$sbr";
    my ( $line,$tmpLine,@tmpLine,@header,$seqNo,$i,%hash );
    return undef if ( ! -r $fileIn or ! -s $fileIn );

    undef %hash;
    undef @header;
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while ($line=<$fhIn>) {
	next if ( $line !~ /^\#\# SEQUENCE PROFILE AND ENTROPY/ );
	last;
    }
    while ($line=<$fhIn>) {
	last if ($line=~ /^\#\#/ );	# insertion section
	last if ( $line=~/^\/\// ); # end of HSSP file
	$tmpLine = $line;
	$seqNo = substr($tmpLine,0,6);
	$pdbNo = substr($tmpLine,6,6);
	$tmpLine = substr($tmpLine,12);

	$tmpLine =~ s/^\s+|\s+$//g;
	@tmpLine = split /\s+/,$tmpLine;
	if ( $line=~/^\s+SeqNo/ ) {
	    @header = @tmpLine;
	    next;
	}
	$seqNo =~ s/\s+//g;
	$pdbNo =~ s/\s+//g;
	$hash{$seqNo}{'pdbNo'} = $pdbNo;
	foreach $i ( 0..$#tmpLine ) {
	    if ( ! defined $header[$i] ) {
		die "HSSP file $fileIn: $i th field in PROFILE not found\nline=$_\n";
	    }
	    $hash{$seqNo}{$header[$i]} = $tmpLine[$i];
	}
    }
    close $fhIn;
    return {%hash};	
}				


sub hsspDist {
    my ( $lali,$pide ) = @_;
    my ($exp);

    if ($lali <= 11) {
	return -(100 + $lali);
    } elsif ($lali > 450) {
	return $pide - 19.5;
    } else {
	$exp = -0.32 * (1 + exp(- $lali / 1000));		
	return $pide - (480 * ($lali ** $exp));
    }
}

1;
