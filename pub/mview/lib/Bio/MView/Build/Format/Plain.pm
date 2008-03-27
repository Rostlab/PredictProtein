# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Plain.pm,v 1.5 1999/04/28 18:21:32 nbrown Exp $

###########################################################################
package Bio::MView::Build::Format::Plain;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying Parse::Format parser
sub parser { 'Plain' }

sub parse {
    my $self = shift;
    my ($rank, $use, $entry, $id, $seq, @hit) = (0);
    
    return  unless defined $self->schedule;
    
    $entry = $self->{'entry'};

    foreach $id (@{$entry->parse(qw(ALIGNMENT))->{'id'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	$seq = $entry->parse(qw(ALIGNMENT))->{'seq'}->{$id};
	
	push @hit, new Bio::MView::Build::Row($rank, $id, '', $seq);
    }

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
