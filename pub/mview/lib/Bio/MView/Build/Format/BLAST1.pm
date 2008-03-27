# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: BLAST1.pm,v 1.3 1999/04/28 18:21:18 nbrown Exp $

###########################################################################
#
# NCBI BLAST 1.4, WashU BLAST 2.0
#
#   blastp, blastn, blastx, tblastn, tblastx
#
###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST1;

use Bio::MView::Build::Format::BLAST;
use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST);

#row filter
sub use_row {
    my ($self, $rank, $nid, $sid, $score, $pval) = @_;
    my $use = $self->SUPER::use_row($rank, $nid, $sid);
    $use = $self->use_hsp($score, $pval)  if $use == 1;
    #warn "BLAST1::use_row($rank, $nid, $sid, $score, $pval) = $use\n";
    return $use;
}

#score/p-value filter
sub use_hsp {
    my ($self, $score, $pval) = @_;
    return 0  if defined $self->{'maxpval'}  and $pval  > $self->{'maxpval'};
    return 0  if defined $self->{'minscore'} and $score < $self->{'minscore'};
    return 1;
}

#BLAST alignments ($h) round non-scientific notation p-values to 2 decimal
#places, but the ranking ($r) reports more places than this: use this function
#to compare the two p-values, returning -1, 0, +1 as $h <=> $r. If $h and $r
#aren't in scientific notation, $h (not $r) may be rounded: treat $h == $r
#when $h > $r and the rounded difference (delta) is less than 0.5, which
#assumes BLAST's rounding was up for delta <= 0.5 and down for delta > 0.5.
sub compare_p {
    shift; my ($h, $r, $dp) = @_;
    return $h <=> $r    if $h =~ /e/i and $r =~ /e/i;
    return -1    if $h < $r;
    return  0    if $h == $r;
    while ($dp--) { $h *= 10; $r *= 10 }
    return  1    if $h - $r > 0.5;
    return  0;    #equal within error
}


###########################################################################
package Bio::MView::Build::Row::BLAST1;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $score, $p, $n) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'score'} = $score;
    $self->{'p'}     = $p;
    $self->{'n'}     = $n;
    bless $self, $type;
}

sub data {
    return sprintf("%5s %9s %2s", 'score', 'P(N)', 'N') unless $_[0]->num;
    sprintf("%5s %9s %2s", $_[0]->{'score'}, $_[0]->{'p'}, $_[0]->{'n'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join("\t", $s, $self->{'score'}, $self->{'p'}, $self->{'n'})
	if $mode eq 'data';
    return join ("\t", $s, 'score', 'p', 'n')
	if $mode eq 'attr';
    return join ("\t", $s, '5N', '9S', '2N')
	if $mode eq 'form';
    '';
}

sub pval  { $_[0]->{'p'} }
sub score { $_[0]->{'score'} }


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub assemble { my $self = shift; $self->assemble_blastp(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::BLAST1(@_);
    $self->{'query_orient'} = $_[$#{@_}-1];
    $self->{'sbjct_orient'} = $_[$#{@_}];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %3s", 'hit') unless $_[0]->num;
    $s .= sprintf(" %3s", $_[0]->{'sbjct_orient'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join("\t", $s, $self->{'query_orient'}, $self->{'sbjct_orient'})
        if $mode eq 'data';
    return join("\t", $s, 'query_orient', 'sbjct_orient')
	if $mode eq 'attr';
    return join("\t", $s, '2S', '2S')
	if $mode eq 'form';
    '';
}

sub range {
    my $self = shift;
    $self->SUPER::range($self->{'query_orient'});
}

sub assemble { my $self = shift; $self->assemble_blastn(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::BLAST1(@_);
    $self->{'query_orient'} = $_[$#{@_}];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %3s", 'qry') unless $_[0]->num;
    $s .= sprintf " %3s", $_[0]->{'query_orient'};
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return(join "\t", $s, $self->{'query_orient'})    if $mode eq 'data';
    return(join "\t", $s, 'query_orient')             if $mode eq 'attr';
    return(join "\t", $s, '2S')                	      if $mode eq 'form';
    '';
}

#start' = int((start+2)/3); stop' = int(stop/3)
sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range($self->{'query_orient'});
    (int(($lo+2)/3), int($hi/3));
}

sub assemble { my $self = shift; $self->assemble_blastx(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::BLAST1(@_);
    $self->{'sbjct_orient'} = $_[$#{@_}];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %3s", 'hit') unless $_[0]->num;
    $s .= sprintf(" %3s", $_[0]->{'sbjct_orient'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join("\t", $s, $self->{'sbjct_orient'})    if $mode eq 'data';
    return join("\t", $s, 'sbjct_orient')             if $mode eq 'attr';
    return join("\t", $s, '2S')	                      if $mode eq 'form';
    '';
}

sub assemble { my $self = shift; $self->assemble_tblastn(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::BLAST1(@_);
    $self->{'query_orient'} = $_[$#{@_}-1];
    $self->{'sbjct_orient'} = $_[$#{@_}];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %3s", 'hit') unless $_[0]->num;
    $s .= sprintf(" %3s", $_[0]->{'sbjct_orient'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join("\t", $s, $self->{'query_orient'}, $self->{'sbjct_orient'})
        if $mode eq 'data';
    return join("\t", $s, 'query_orient', 'sbjct_orient')
	if $mode eq 'attr';
    return join("\t", $s, '2S', '2S')
	if $mode eq 'form';
    '';
}

#start' = int((start+2)/3); stop' = int(stop/3)
sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range($self->{'query_orient'});
    (int(($lo+2)/3), int($hi/3));
}

sub assemble { my $self = shift; $self->assemble_tblastx(@_) }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST1::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub parse {
    my $self = shift;
    my ($rank, $use, %idx, @hit, $match) = (0);
    
    #all frames done?
    return     unless defined $self->schedule;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    push @hit, new Bio::MView::Build::Row::BLAST1::blastp
	(
	 '',
	 $match->{'query'},
	 $match->{'summary'},
	 '',
	 '',
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'}, $match->{'p'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastp
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n, $score, $p) = (0, 0, 1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'} if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}     if $aln->{'p'}     < $p;
	    $n++;

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'score'} = $score;
	$hit->[$idx->{$sum->{'id'}}]->{'p'}     = $p;
	$hit->[$idx->{$sum->{'id'}}]->{'n'}     = $n;
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
					  $hit->[$idx->{$sum->{'id'}}]->{'p'},
					  2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::blastp
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});
	    
	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}

sub parse {
    my $self = shift;
    my ($rank, $use, %idx, @hit, $match) = (0);
    
    #all strands done?
    return     unless defined $self->schedule_by_strand;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    push @hit, new Bio::MView::Build::Row::BLAST1::blastn
	(
	 '',
	 $match->{'query'},
	 $match->{'summary'},
	 '',
	 '',
	 '',
	 $self->strand,
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'}, $match->{'p'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $self->strand,
	     '',
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::blastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,
		     $orient,
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score1;
	    $hit->[$idx->{$key}]->{'p'}     = $p1;
	    $hit->[$idx->{$key}]->{'n'}     = $n1;
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score2;
	    $hit->[$idx->{$key}]->{'p'}     = $p2;
	    $hit->[$idx->{$key}]->{'n'}     = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $orient, @tmp);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	#we don't know which hit orientation was chosen for the ranking
	#since BLASTN neglects to tell us. it is conceivable that two sets 
	#of hits in each orientation could have the same frag 'n' count.
	#gather both, then decide which the ranking refers to.
	@tmp = (); foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #ignore unranked fragments
	    $key = $aln->{'n'} . $sum->{'id'};
	    next  unless exists $idx->{$key};

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same p-value.
	$orient = '?'; foreach $aln (@tmp) {
	    if ($self->compare_p($aln->{'p'},
				 $hit->[$idx->{$sum->{'id'}}]->{'p'},
				 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach $aln (@tmp) {

	    #ignore other subjct orientation
	    next unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher p-value than ranked
	    next unless $self->compare_p($aln->{'p'},
					 $hit->[$idx->{$sum->{'id'}}]->{'p'},
					 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'} = $orient;
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};
	
	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::blastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,
		     $aln->{'sbjct_orient'},
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;    
}

sub parse {
    my $self = shift;
    my ($rank, $use, %idx, @hit, $match) = (0);
    
    #all strands done?
    return     unless defined $self->schedule_by_strand;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    push @hit, new Bio::MView::Build::Row::BLAST1::blastx
	(
	 '',
	 $match->{'query'},
	 $match->{'summary'},
	 '',
	 '',
	 '',
	 $self->strand,
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'}, $match->{'p'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $match->{'query_frame'},
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};
	
	my ($n, $score, $p) = (0, 0, 1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'} if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}     if $aln->{'p'}     < $p;
	    $n++;

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'score'}        = $score;
	$hit->[$idx->{$sum->{'id'}}]->{'p'}            = $p;
	$hit->[$idx->{$sum->{'id'}}]->{'n'}            = $n;
	$hit->[$idx->{$sum->{'id'}}]->{'query_orient'} = $self->strand;
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
					  $hit->[$idx->{$sum->{'id'}}]->{'p'},
					  2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}
    }
    $self;
}
    
sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! exists $idx->{$key}) {

		push @$hit, new Bio::MView::Build::Row::BLAST1::blastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub parse {
    my $self = shift;
    my ($rank, $use, %idx, @hit, $match) = (0);
    
    #all frames done?
    return     unless defined $self->schedule;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    push @hit, new Bio::MView::Build::Row::BLAST1::tblastn
	(
	 '',
	 $match->{'query'},
	 $match->{'summary'},
	 '',
	 '',
	 '',
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'}, $match->{'p'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::tblastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $match->{'sbjct_frame'},
	    );
	
	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $orient,
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score1;
	    $hit->[$idx->{$key}]->{'p'}     = $p1;
	    $hit->[$idx->{$key}]->{'n'}     = $n1;
	}
	#override row data (hit 1 orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score2;
	    $hit->[$idx->{$key}]->{'p'}     = $p2;
	    $hit->[$idx->{$key}]->{'n'}     = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq 
		$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'};

	    $key = $aln->{'n'} . $sum->{'id'};
	    
	    #ignore unranked fragments
	    next  unless exists $idx->{$key};
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
					  $hit->[$idx->{$sum->{'id'}}]->{'p'},
					  2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $aln->{'sbjct_frame'},
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;    
}

sub parse {
    my $self = shift;
    my ($rank, $use, %idx, @hit, $match) = (0);
    
    #all frames done?
    return     unless defined $self->schedule_by_strand;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    push @hit, new Bio::MView::Build::Row::BLAST1::tblastx
	(
	 '',
	 $match->{'query'},
	 $match->{'summary'},
	 '',
	 '',
	 '',
	 $self->strand,
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'}, $match->{'p'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::tblastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $self->strand,
	     $match->{'sbjct_frame'},
	    );
	
	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastx
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,
		     $orient,
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	    
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score1;
	    $hit->[$idx->{$key}]->{'p'}     = $p1;
	    $hit->[$idx->{$key}]->{'n'}     = $n1;
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'score'} = $score2;
	    $hit->[$idx->{$key}]->{'p'}     = $p2;
	    $hit->[$idx->{$key}]->{'n'}     = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq 
		$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'};

	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
					  $hit->[$idx->{$sum->{'id'}}]->{'p'},
					  2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,
		     $aln->{'sbjct_frame'},
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
1;
