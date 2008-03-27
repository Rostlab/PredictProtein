# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Ruler.pm,v 1.3 1999/04/28 18:21:11 nbrown Exp $

###########################################################################
package Bio::MView::Align::Ruler;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Row);

sub new {
    my $type = shift;
    my ($length) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'length'} = $length;
    $self->{'class'}  = 'ruler';

    $self->reset_display;

    $self;
}

sub id     { $_[0] }
sub string { '' }
sub length { $_[0]->{'length'} }

sub reset_display { 
    $_[0]->{'display'} =
	{
	 'type'     => 'ruler',
	 'label0'   => '',
	 'label1'   => '',
	 'label2'   => '',
	 'label3'   => '',
	 'label4'   => '',
	 'range'    => [],
	 'number'   => 1,
	};
    $_[0];
}

#sub color {
#    my $self = shift;
#    $self;
#}

sub color_by_type {}
sub color_by_identity {}
sub color_by_consensus_sequence {}
sub color_by_consensus_group {}


###########################################################################
1;
