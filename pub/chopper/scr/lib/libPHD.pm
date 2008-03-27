package      libPHD;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(getFieldPHD isProfRDB);
@EXPORT_OK = qw(getLenPHD);


#=================================================================
# subroutines to parse HMMER output
#=================================================================

sub getFieldPHD {
    my ($fileIn, $fields) = @_;
    my $sbr = "getFieldPHD";
    my ($f,%getField,$fhIn,@headers,@indices,$i,$no,@tmpLine);
    my ($field,$value,%hash);

    undef %hash;
    if ( ! -f $fileIn ) {
	return (0,undef,"file not found");
    }

    foreach $f ( @$fields ) {
	$getField{$f} = 1;
    }

    $fhIn = "IN_$sbr";
    open ($fhIn,$fileIn) or die "cannot open $fileIn:$!";
    while (<$fhIn>) {
	next if ( /^\#/ );
	s/^\s+|\s+$//g;
	if ( /^No\t/ ) {
	    @headers = split /\t+/;
	    for $i ( 0..$#headers ) {
		if ( $getField{$headers[$i]} ) {
		    push @indices, $i;
		}
	    }
	    last;
	}
    }
    
    while ( <$fhIn> ) {
	s/^\s+|\s+$//g;
	@tmpLine = split /\t+/;
	$no = $tmpLine[0];
	foreach $i ( @indices ) {
	    $field = $headers[$i];
	    $value = $tmpLine[$i];
	    if ( ! defined $value ) {
		close $fhIn;
		return (0,undef,"$field value for residue $no not found in $fileIn");
	    } 
	    $hash{$no}{$field} = $value;
	}
    }
    close $fhIn;
    return (1,{%hash},"ok");
}

sub getLenPHD {
    my ( $file ) = @_;
    my $sbr = "getLenPHD";
    my $fh = "IN_$sbr";
    my ($line,$prot_len);

    return undef if ( ! -s $file );

    open ($fh,$file) or die "cannot open $file:$!";
    while ($line=<$fh>) {
	if ( $line =~ /^\#\s+VALUE\s+PROT_NRES\s+:\s+(\d+)/ ) {
	    $prot_len = $1;
	    last;
	}
    }
    close $fh;
    return $prot_len;
}

sub isProfRDB {
    my ( $file ) = @_;
    my $sbr = "isProfRDB";
    my $fh = "IN_$sbr";
    my ($prot_len,$line,$has_header,$res_no);

    return 0 if ( ! -s $file );

    $prot_len = $has_header = 0;
    open ($fh,$file) or die "cannot open $file:$!";
    while ($line=<$fh>) {
	if ( $line =~ /^\#\s+VALUE\s+PROT_NRES\s+:\s+(\d+)/ ) {
	    $prot_len = $1;
	    next;
	}
	next if ( $line =~ /^\#/ );
	if ( $line =~ /^No\s+AA\s+/ ) {
	    $has_header = 1;
	    next;
	}
	$line =~ s/^\s+|\s+$//g;
	if ( $line =~ /^(\d+)\s+/ ) {
	    $res_no = $1;
	}
    }
    close $fh;
    if ( $has_header and $prot_len and $prot_len == $res_no ) {
	return 1;
    } else {
	return 0;
    }
}
 
1;
