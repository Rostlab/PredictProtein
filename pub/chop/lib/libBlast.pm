package      libBlast;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(isBlast rdBlastHsp);
@EXPORT_OK = qw(getQueryName getQueryLength);


#=============================================================
# subroutines for parsing blast files
# getQueryLength() returns the length of query, -1 if error
# hspView() display HSP in 'graphic' way
# rdBlastHsp() returns all HSPs as list of hash
# isBlast() check the integrety of blast file
#=============================================================

sub getQueryName {
    my ( $fileBlast ) = @_;
    my $query = "";
    if ( ! -f $fileBlast ) {
	return "";
    }

    open (BLAST, $fileBlast) or die "cannot open $fileBlast:$!";
    while (<BLAST>) {
	if ( /^Query=\s*(\S+)\s+/ ) {
	    $query = $1;
	    last;
	}
    }
    close BLAST;
    return $query;
}



sub getQueryLength {
    my ( $fileBlast ) = @_;
    if ( ! -f $fileBlast ) {
	return -1;
    }
    my $queryLength = -1;

    open (BLAST, $fileBlast) or die "cannot open $fileBlast:$!";
    while (<BLAST>) {
	next if ( $_ !~ /\w+/ );
	s/,//g;
	if ( /^\s+\((\d+)\s+letters\)/ ) {
	    $queryLength = $1;
	} 
	last if ( /^Database\:/ );
    }
    close BLAST;
    return $queryLength;
}


sub hspView {
    my ( $fileBlast, $eCutoff, $interval ) = @_;
    my ( $ctInterval,$spaces,@overlap,$overlap,$overlapStart,$overlapEnd);
    my ( $mark,$ctMarks,$symbol);
    if ( ! -f $fileBlast ) {
	print STDERR "*** ERROR: $fileBlast not found, exit..\n";
	return;
    }
    if ( ! defined $eCutoff ) {
	$eCutoff = 10;
    }

    if ( defined $interval ) {
	if ( $interval < 5 ) {
	    print STDERR "*** ERROR: will not print by the interval of $interval, exit..\n";
	    return;
	}
    } else {
	$interval = 10;
    }

    $symbol = '-';

    $queryId = $fileBlast;
    $queryId =~ s/\..*//g;
    $queryId =~ s/.*\///g;
    
    $queryLength = &getQueryLength($fileBlast);
    if ( $queryLength == -1 ) {
	print STDERR "*** ERROR: Uable to get query length for $fileBlast, exit..\n";
	return;
    }
    print "query=$queryId\tlength=$queryLength\teCutoff=$eCutoff\n\n";

    $ctInterval = int($queryLength/$interval);
    if ( $ctInterval != $queryLength/$interval ) {
	$ctInterval++;
    }
    $ctMarks = int($ctInterval/10);
    printf "%-15s",' ';
    for $i ( 1..$ctMarks ) {
	$mark = $i * $interval * 10;
	printf "%10d",$mark;
    }
    print "\n";

    printf "%-15s",$queryId;
    
    
    for $i ( 1..$ctInterval ) {
	print $symbol;
    }
    print "\n";
    #return;

    $hsps = &rdBlastHsp($fileBlast);
    $spaces = ' 'x$ctInterval;
    #print "xx $spaces xx\n";die;
    foreach $hsp ( @$hsps ) {
	next if ( $hsp->{'expect'} > $eCutoff ); # skip irrelevant hits
	@overlap = split //,$spaces;
	#print join('',@overlap),"xx\n";die;
	$homoId = $hsp->{'nameLine'};
	$homoId =~ s/\s+.*//g;
	$homoId = substr($homoId,0,14);
	$overlapStart = int($hsp->{'queryStart'}/$interval);
	$overlapEnd = int($hsp->{'queryEnd'}/$interval);
	for $i ( $overlapStart..$overlapEnd ) {
	    $overlap[$i] = $symbol;
	}
	$overlap = join('',@overlap);
	printf "%-15s%s\n",$homoId,$overlap;
    }
    return;
}

sub rdBlastHsp {
    my ( $fileBlast ) = @_;
    
    my ( @hspField, $patternRound,$ctRound, $isInHit);
    #my ( $queryStart,$queryEnd,$subjStart,$subjEnd);
    #my ($nameLine, $lengthLine,$subjLength,$scoreLine,$score,$expect);
    #my ($identityLine,$ctIdent,$alignLen,$percIdent,$ctPositive,$percPositive);
    #my ($queryLineStart,$queryLineEnd,$subjLineStart,$subjLineEnd);
    my ( $hsp, $f );
    my @hsps = ();

    # get round of PSI-BLAST
    @hspField = ('nameLine','subjLength','score','expect',
		 'alignLen','ctIdent','percIdent','ctPositive',
		 'percPositive','gap','queryStart',
		 'queryEnd','subjStart','subjEnd');

    #print "xx $fileBlast\n";

    $patternRound = "'^Results from round'";
    $ctRound = `egrep $patternRound $fileBlast | wc -l`;
    $ctRound =~ s/\D+//g;

    #print "$ctRound round of blast search\n";
    
    open ( BLAST, $fileBlast ) or die "cannot open $fileBlast:$!";
    while ( <BLAST> ) {
	if ( $ctRound != 0 ) {
	    next if ( $_ !~ /^Results from round $ctRound/ );
	} else {
	    next if ( $_ !~ /^Searching/);
	}
	
	last;
    } 

    $isInHit = 0;
    $queryStart=$queryEnd=$subjStart=$subjEnd=0;
    while ( <BLAST> ) {
	#print $_;
				# end of alignment section
	if (/^\s*Database\:/ ) {
	    if ( $queryStart != 0 ) { # print the last alignment
		foreach $f ( @hspField ) {
		    $theHsp{$f} = $$f;
		}
		#print "xx theHsp->nameLine = ".$theHsp{'nameLine'}."\n";
		push @hsps, {%theHsp};
	    }
	    last;
	}

	next if ( $_ !~ /\w+/ );	# skip blank lines

	if ( /^\s*\>/ ) {		# header line

					# record info for the last one
	    if ( $queryStart != 0 ) {
		foreach $f ( @hspField ) {
		    $theHsp{$f} = $$f;
		}
		#print "xx theHsp->nameLine = ".$theHsp{'nameLine'}."\n";
		push @hsps, {%theHsp};
	    }
	    
	    $queryStart=$queryEnd=$subjStart=$subjEnd=0;
		
	    $isInHit = 1;
	    chomp($nameLine = $_); #print "xx nameLine=$nameLine\n";
	    chomp($lengthLine = <BLAST>);
	    #print $lengthLine;
	    while ( $lengthLine !~ /\s*Length\s*=\s*(\d+)/ ) {
		$nameLine .= $lengthLine;
		chomp($lengthLine = <BLAST>);
		#die "seems not a valid line for subject length\n$lengthLine\n";
	    }
	    $subjLength = $lengthLine; 
	    $subjLength =~ s/\D+//g;
	    $nameLine =~ s/^\s*\>//;
	    
	} else {
	    next if ( ! $isInHit );
	    if ( /^\s*Score/ ) {	# start of a new HSP
		
				# record info for the last one
		if ( $queryStart != 0 ) { #die "reached here??\n";
		    #print "xx queryStart = $queryStart\n";
		    foreach $f ( @hspField ) {
			$theHsp{$f} = $$f;
		    }
		    #print "xx theHsp->nameLine = ".$theHsp{'nameLine'}."\n";
		    push @hsps, {%theHsp};
		}

		
		$scoreLine = $_;
		$scoreLine =~ s/\s+//g;
		if ( $scoreLine =~ /Score=(.*),Expect=(.*)/ ) {
		    $score = $1;
		    $expect = $2;
		    if ( $expect =~ /^e/ ) {
			$expect = '1'.$expect;
		    }
		}
		
		$identityLine = <BLAST>;
		$identityLine =~ s/\s+//g;
		$gapEntry = "";
		if ( $identityLine =~ 
		     /Identities=(\d+)\/(\d+)\((\d+)\%\),Positives=(\d+)\/(\d+)\((\d+)\%\)(.*)$/ ) {
		    ($ctIdent,$alignLen,$percIdent,
		     $ctPositive,$percPositive) = ($1,$2,$3,$4,$6);
		    $gapEntry = $7 if ( $7 );
		    if ( $gapEntry =~ /Gaps=(\d+)\/(\d+)/ ) {
			$gap = $1;
		    } else {
			$gap = 0;
		    }
		}
		
		$queryStart=$queryEnd=$subjStart=$subjEnd=0;
	    } else {
		if ( /^Query\s*:\s*(\d+)\D+(\d+)/ ) { 
		    $queryLineStart = $1; #print "xx line start = $queryLineStart\n";
		    $queryLineEnd = $2;	
		    if ( $queryStart == 0 ) {
			$queryStart = $queryLineStart;
			#print "xx start=$queryStart\n";
		    }
		    if ( $queryEnd < $queryLineEnd ) {
			$queryEnd = $queryLineEnd;
		    }
		} elsif ( /^Sbjct\s*:\s*(\d+)\D+(\d+)/ ) {
		    $subjLineStart = $1;
		    $subjLineEnd = $2;
		    if ( $subjStart == 0 ) {
			$subjStart = $subjLineStart;
		    }
		    if ( $subjEnd < $subjLineEnd ) {
			$subjEnd = $subjLineEnd;
		    }
		} else {
		    next;
		}
	    }
	}
    }
    close BLAST;

    return [@hsps];
}




sub isBlast {			# ==================================
				# check the integrety of blast file
				# ==================================
    ($fileBlast) = @_;
    my $isBlast = 0;
    return 0 if ( ! -e $fileBlast);
    open ( FHBLAST, $fileBlast) or die "cannot open $fileBlast:$!";
    while (<FHBLAST>) {
	if (/^Matrix: BLOSUM62/i) {
	    $isBlast = 1;
	}
    }
    close FHBLAST;
    return $isBlast;
}


sub rdSaf {
    my ( $safRef ) = @_;
    my ( @saf, $ctQuery,  $nAlign, $nAlignPdb, $safLine, $currentPos);
    my ( $seqLen,  $name, $safSeq,$lenLine,$seqPerLine, $lineBeg);
    my ( $lineEnd, @seq,  $i, $pos, @pdb, $isPdb, $ctPdbReg, $ctPdbRes);
    my ( @pdbEnd, @pdbBeg, $pdbReg);

    #$[ = 1;

    @saf = @$safRef;

    my $errMsg = "";

				# get nAlign info
    $ctQuery = 0;
    $nAlign = $nAlignPdb = 0;
    foreach $safLine ( @saf ) {
	next if ( $safLine !~ /^\w+/ );
	if ( $safLine =~ /^query/ ) {
	    $ctQuery++;
	    last if ( $ctQuery == 2 );
	    next;
	}
	$nAlign++;
	$nAlignPdb++ if ( $safLine =~ /^pdb/ );
    }
    
				# get aaInPdb info

    $currentPos = 0;
    $seqLen = 0;
    foreach $safLine ( @saf ) {
	next if ( $safLine =~ /^\#/ );
	next if ( $safLine !~ /\w+/ );

	chomp $safLine;
	( $name, $safSeq ) = split /\s+/,$safLine,2;
	if ( ! defined $safSeq ) {
	    $errMsg .= "safSeq not defined\n$id\n$safLine\n$safSeq\n";
	}
	$safSeq =~ s/\s+//g;
	$lenLine = length($safSeq);
	
	if ( $name !~ /\|/ or $name eq "query" ) { # query sequence
	    $seqPerLine = $lenLine;
	    $seqLen += $seqPerLine;
	    $lineBeg = $currentPos;
	    $lineEnd = $currentPos + $seqPerLine;
	    $currentPos = $lineEnd;
	    next;
	}
	
	next if ( $safLine !~ /^pdb\|/);
	
	if ( $seqPerLine != $lenLine ) {
	    $errMsg .= "$fileSaf: $safLine\nquery and target have diff length\n";
	    return "";
	}
	
	@seq = split //,$safSeq;
	for $i ( 1..$seqPerLine) {
	    $pos = $lineBeg + $i;
	    next if ( defined $pdb[$pos] and $pdb[$pos] == 1 );
	    if ( ! defined $seq[$i] ) {
		$errMsg .= "xx $id\n$safLine\n$safSeq\nseq[$i] not defined\n";
		die;
	    }
	    if ( $seq[$i] ne '.' ) {
		$pdb[$pos] = 1;
	    }
	}
    }
    

    if ( $seqLen == 0 ) {
	$errMsg .= "$fileSaf: seqLen is 0, probably no 'query' line\n";
	return "";
    }


    $isPdb = 0;
    $ctPdbReg = 0;
    $ctPdbRes = 0;
    for $i ( 1..$seqLen ) {
	if ( !defined $pdb[$i] ) {
	    $pdb[$i]=0;
	}
	if ( $pdb[$i] == 1 ) {
	    $ctPdbRes++;
	    if ( $isPdb ) {
		next;
	    } else {
		$isPdb = 1;
		$ctPdbReg++;
		$pdbBeg[$ctPdbReg] = $i;
	    }
	} else {
	    if ( $isPdb ) {
		$pdbEnd[$ctPdbReg] = $i - 1;
		$isPdb = 0;
	    } else {
		next;
	    }
	}
    }
    if ( $isPdb ) {
	$pdbEnd[$ctPdbReg]=$seqLen;
    }

    #print "xx $ctPdbReg\n";die;
    $pdbReg = "";
    for $i ( 1..$ctPdbReg ) {
	$pdbReg .= $pdbBeg[$i].'-'.$pdbEnd[$i].',';
    }
    $pdbReg =~ s/,$//;

    return ( $seqLen, $nAlign, $nAlignPdb, $ctPdbRes, $pdbReg );
}




1;







