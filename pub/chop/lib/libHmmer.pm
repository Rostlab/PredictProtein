package      libHmmer;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(isHmmer);
@EXPORT_OK = qw(parseHmmer);


#=================================================================
# subroutines to parse HMMER output
#=================================================================

sub isHmmer {
    my ( $fileIn ) = @_;
    return 0 if ( ! -f $fileIn );
    my ( $foundHmm, $foundEnd );
    $foundHmm = $foundEnd = 0;

    open (IN, $fileIn) or die "cannot open $fileIn:$!";

    while (<IN>) {
        $foundHmm = 1 if ( /^HMMER/ );
        $foundEnd = 1 if ( /^\/\// );
    }
    close PFAM;
    return ( $foundHmm and $foundEnd );
}


sub parseHmmer {
    my ( $fileHmm ) = @_;
    return undef if ( ! -e $fileHmm );

    local ($model,$seq_f,$seq_t,$seq_isBegin,$seq_isEnd);
    local ($hmm_f,$hmm_t,$hmm_isBegin,$hmm_isEnd,$score,$expect);
    my (@hmmFields,$f,%theHmm,@hmms,@tmp);

    undef %theHmm;
    undef @hmms;

    @hmmFields = ( 'model','seq_f','seq_t','seq_isBegin','seq_isEnd',
		   'hmm_f','hmm_t','hmm_isBegin','hmm_isEnd','score',
		   'expect' );
    
    open (HMM,$fileHmm) or die "cannot open $fileHmm:$!";
    while (<HMM>) {
	next if ( $_ !~ /^Parsed for domains/ );
	last;
    }
    while (<HMM>) {
	last if ( /^Alignments/ );
	next if ( /^Model\s+/);
	next if ( /^------/ );
	next if ( $_ !~ /\w+/ );
	last if ( /^\s*\[no hits above thresholds\]/ );
	chomp;
	
	#print $_."\n";
	s/^\s+|\s+$//g;
	@tmp = split /\s+/;
	($model,$seq_f,$seq_t,$hmm_f,$hmm_t,$score,$expect) 
	    = @tmp[0,2,3,5,6,8,9];
	
	$seq_isBegin = &hmmSymbol2bool(substr($tmp[4],0,1));
	$seq_isEnd = &hmmSymbol2bool(substr($tmp[4],1,1));
	
	$hmm_isBegin = &hmmSymbol2bool(substr($tmp[7],0,1));
	$hmm_isEnd = &hmmSymbol2bool(substr($tmp[7],1,1));
	
	
	foreach $f ( @hmmFields ) {
	    #print "xx field=$f\n";
	    #print "xx model=$model\n";
	    #print "xx $$f\n";
	    if ( ! defined $$f ) {
		print "xx $f not defined\n";
		die;
	    }
	    $theHmm{$f} = $$f;
	    next if ( $f eq 'model' and $$f !~ /^PF/);
	    $theHmm{$f} =~ s/\s+//g;
	}
	push @hmms, {%theHmm};
    }
    close HMM;
    if ( @hmms ) {
	return [@hmms];
    } else {
	return undef;
    }
}

sub hmmSymbol2bool {
    my ( $sym ) = @_;
    if ( $sym eq '.' ) {
	return 0;
    } elsif ( $sym eq ']' or $sym eq '[' ) {
	return 1;
    } else {
	die "'$sym' is not a valid HMM symbol, should be either [] or .\n";
    }
}
 
1;
