# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA3.pm,v 1.4 1999/12/01 13:14:38 nbrown Exp $

###########################################################################
#
# FASTA 3
#
#   fasta, tfastx
#
###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA3;

use Bio::MView::Build::Format::FASTA2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA3;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

#Handles the fasta 3.3 format change using 'bits' rather than older z-scores
#with reduction in importance of 'initn' and 'init1'.

sub new {
    my $type = shift;
    my ($num, $id, $desc, $opt, $bits, $e) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'initn'} = 0;    #unknown in post-3.3 versions
    $self->{'init1'} = 0;    #unknown in post-3.3 versions
    $self->{'opt'}   = $opt;
    $self->{'bits'}  = $bits;
    $self->{'e'}     = $e;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %7s %9s", 'opt', 'bits' , 'E-value') unless $_[0]->num;
    sprintf("%5s %7s %9s", $_[0]->{'opt'}, $_[0]->{'bits'}, $_[0]->{'e'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join "\t", $s, $self->{'bits'}, $self->{'e'}
        if $mode eq 'data';
    return join "\t", $s, 'bits', 'E-value'
	if $mode eq 'attr';
    return join "\t", $s, '7S', '9S'
	if $mode eq 'form';
    '';
}


###########################################################################
package Bio::MView::Build::Row::FASTA3::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA3(@_);
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
package Bio::MView::Build::Row::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2::tfastx);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA3::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::fasta);

sub parse {
    my $self = shift;
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #if this is a pre-3.3 fasta call the superclass parser
    if ($match->{'version'} =~ /^3\.(\d+)/ and $1 < 3) {
	return $self->SUPER::parse(@_);
    }

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

    push @hit, new Bio::MView::Build::Row::FASTA3::fasta
	(
	 '',
	 $query,
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

	$key = $match->{'id'} . $match->{'opt'} . $match->{'expect'};

	push @hit, new Bio::MView::Build::Row::FASTA3::fasta
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'desc'},
	     $match->{'opt'},
	     $match->{'bits'},
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

	$key = $sum->{'id'} . $sum->{'opt'} . $sum->{'expect'};

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
package Bio::MView::Build::Format::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::tfastx);


###########################################################################
1;
