# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Row.pm,v 1.14 1999/01/27 00:06:44 nbrown Exp $

###########################################################################
package Bio::MView::Align::Row;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Ruler;
use Bio::MView::Align::String;
use Bio::MView::Align::Identity;
use Bio::MView::Align::Consensus;
use strict;

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    my $self = shift;
    local $_;
    foreach (sort keys %$self) {
	printf "%15s => %s\n", $_, $self->{$_};
    }
    $self;
}

sub set_display {
    my $self = shift;
    my ($key, $val, @tmp, %tmp);
    #$self->print;
    while ($key = shift @_) {

	$val = shift @_;

	#have to copy referenced data in case caller iterates over
	#many instances of self and passes the same data to each!
	if (ref $val eq 'HASH') {
	    %tmp = %$val;
	    $val = \%tmp;
	} elsif (ref $val eq 'ARRAY') {
	    @tmp = @$val;
	    $val = \@tmp;
	}
	#warn "($key) $self->{'display'}->{$key} --> $val\n";
	$self->{'display'}->{$key} = $val;
    }

    $self;
}

sub get_display { $_[0]->{'display'} }


###########################################################################
1;
