# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: MSF.pm,v 1.4 1999/04/28 18:21:27 nbrown Exp $

###########################################################################
package Bio::MView::Build::Row::MSF;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build::Row);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq, $weight) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc, $seq);
    $self->{'weight'} = $weight;
    bless $self, $type;
}

#sub data  { sprintf("%5s", $_[0]->{'weight'}) }

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join "\t", $s, $self->{'weight'}    if $mode eq 'data';
    return join "\t", $s, 'weight'             if $mode eq 'attr';
    return join "\t", $s, '5N'                 if $mode eq 'form';
    '';
}


###########################################################################
package Bio::MView::Build::Format::MSF;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying Parse::Format parser
sub parser { 'MSF' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $wgt, $seq, @hit) = (0);

    return  unless defined $self->schedule;

    foreach $id (@{$self->{'entry'}->parse(qw(NAME))->{'order'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	$wgt = $self->{'entry'}->parse(qw(NAME))->{'seq'}->{$id}->{'weight'};
	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Row::MSF($rank,
						   $id,
						   '',
						   $seq,
						   $wgt,
						  );
    }

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
