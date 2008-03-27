# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Identity.pm,v 1.1 1999/01/27 00:06:39 nbrown Exp $

###########################################################################
package Bio::MView::Align::Identity;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;
use strict;

use vars qw(@ISA $Debug);

@ISA = qw(Bio::MView::Align::String);

$Debug = 0;

sub new {
    my $type = shift;
    warn "${type}::new() (@_)\n"    if $Debug;
    if (@_ < 4) {
	die "${type}::new() missing arguments\n";
    }
    my ($id1, $id2, $string, $identity) = (@_);

    my $self = new Bio::MView::Align::String($id1 . 'x' . $id2, $string);

    $self->{'identity'} = $identity;
    $self->{'parentid'} = $id1;
    $self->{'class'}    = 'identity';

    bless $self, $type;
}

sub get_identity { $_[0]->{'identity'} }
sub get_parentid { $_[0]->{'parentid'} }


###########################################################################
1;
