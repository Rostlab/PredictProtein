# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA2.pm,v 1.4 1999/04/28 18:21:24 nbrown Exp $

###########################################################################
#
# FASTA 2
#
#   fasta, tfastx
#
###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA2;

use Bio::MView::Build::Format::FASTA;
use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $initn, $init1, $opt, $z, $e) = @_;
    my $self = new Bio::MView::Build::Row::FASTA(@_);
    $self->{'z'} = $z;
    $self->{'e'} = $e;
    bless $self, $type;
}

sub data  {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %7s %9s", 'z-sc', 'E-value') unless $_[0]->num;
    $s .= sprintf " %7s %9s", $_[0]->{'z'}, $_[0]->{'e'};
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join "\t", $s, $self->{'z'}, $self->{'e'}    if $mode eq 'data';
    return join "\t", $s, 'Z', 'E'                      if $mode eq 'attr';
    return join "\t", $s, '7S', '9S'                    if $mode eq 'form';
    '';
}


###########################################################################
package Bio::MView::Build::Row::FASTA2::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA2(@_);
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

sub assemble { my $self = shift; $self->assemble_fasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA2::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA2(@_);
    $self->{'frame'} = $_[$#{@_}];
    bless $self, $type;
}

sub data  {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %3s", 'hit') unless $_[0]->num;
    $s .= sprintf " %3s", $_[0]->{'frame'};
    $s;
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join "\t", $s, $self->{'frame'}    if $mode eq 'data';
    return join "\t", $s, 'frame'             if $mode eq 'attr';
    return join "\t", $s, '1S'                if $mode eq 'form';
    '';
}


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA2::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

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
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #all strands done?
    return     unless defined $self->schedule_by_strand;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    push @hit, new Bio::MView::Build::Row::FASTA2::fasta
	(
	 '',
	 $query,
	 '',
	 '',
	 '',
	 '',
	 '',
	 '',
	 $self->strand,
	 '',
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR opt
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'opt'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'expect'};

	push @hit, new Bio::MView::Build::Row::FASTA2::fasta
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'desc'},
	     $match->{'initn'},
	     $match->{'init1'},
	     $match->{'opt'},
	     $match->{'zscore'},
	     $match->{'expect'},
	     $self->strand,
	     '',
	    );
	$hit{$key} = $#hit;
    }

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	$key = $sum->{'id'} . $sum->{'initn'} . $sum->{'expect'};

	#only read hits already seen in ranking
	next  unless exists $hit{$key};

	#override the row description
	if ($sum->{'desc'}) {
	    $hit[$hit{$key}]->{'desc'} = $sum->{'desc'};
	}

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
            next  unless $aln->{'query_orient'} eq $self->strand;

	    $aln = $match->parse(qw(ALN));
	    
	    #$aln->print;
	    
	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});
	    
	    $hit[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		);
	    
	    $hit[$hit{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		);

	    #override row data
	    $hit[$hit{$key}]->{'sbjct_orient'} = $aln->{'sbjct_orient'};
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print; print "\n" } @hit;

    return \@hit;
}


###########################################################################
package Bio::MView::Build::Format::FASTA2::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

sub parse {
    my $self = shift;
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    return     unless defined $self->schedule;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    push @hit, new Bio::MView::Build::Row::FASTA2::tfastx
	(
	 '',
	 $query,
	 '',
	 '',
	 '',
	 '',
	 '',
	 '',
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR opt
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'opt'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'expect'} . 
	    lc $match->{'frame'};
	
	push @hit, new Bio::MView::Build::Row::FASTA2::tfastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'desc'},
	     $match->{'initn'},
	     $match->{'init1'},
	     $match->{'opt'},
	     $match->{'zscore'},
	     $match->{'expect'},
	     $match->{'frame'} eq 'f' ? '+' : '-',
	    );
	$hit{$key} = $#hit;
    }

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(HIT))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	$key = $sum->{'id'} . $sum->{'initn'} . $sum->{'expect'} .
	    lc $sum->{'frame'};

	#only read hits accepted in ranking
	next  unless exists $hit{$key};

	#override the row description
	if ($sum->{'desc'}) {
	    $hit[$hit{$key}]->{'desc'} = $sum->{'desc'};
	}

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {
	    $aln = $match->parse(qw(ALN));
	    
	    #$aln->print;
	    
	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});
	    
	    $hit[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		);
	    
	    $hit[$hit{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		);
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK HIT));

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;