# Copyright (c) 1998  Nigel P. Brown. \$Id: PIR.pm,v 1.3 1999/04/28 18:21:29 nbrown Exp $

###########################################################################
package Bio::MView::Build::Format::PIR;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying Parse::Format parser
sub parser { 'PIR' }

sub parse {
    my $self = shift;
    my ($rank, $use, $rec, @hit) = (0);

    return  unless defined $self->schedule;

    foreach $rec ($self->{'entry'}->parse(qw(SEQ))) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $rec->{'id'})) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	push @hit, new Bio::MView::Build::Row($rank,
					      $rec->{'id'},
					      $rec->{'desc'},
					      $rec->{'seq'},
					     );
    }
    
    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
