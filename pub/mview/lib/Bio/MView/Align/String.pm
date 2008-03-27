# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: String.pm,v 1.5 1999/07/01 14:23:25 nbrown Exp $

###########################################################################
package Bio::MView::Align::String;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;
use strict;

use vars qw(@ISA %Template);

@ISA = qw(Bio::MView::Align::Row);

%Template = 
    (
     'id'      => undef,     #identifier
     'from'    => undef,     #start number of sequence
     'class'   => undef,     #own type
     'string'  => undef,     #alignment string
     'display' => undef,     #hash of display parameters
    );


sub new {
    my $type = shift;
    #warn "${type}::new() (@_)\n";
    if (@_ < 2) {
	die "${type}::new() missing arguments\n";
    }
    my ($id, $string) = (@_);

    my $self = { %Template };

    $self->{'id'}     = $id;
    $self->{'from'}   = $string->lo;
    $self->{'class'}  = 'string';
    $self->{'string'} = $string;

    bless $self, $type;

    $self->reset_display;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub id     { $_[0]->{'id'} }
sub string { $_[0]->{'string'}->string }
sub array  { split //, $_[0]->{'string'}->string }
sub from   { $_[0]->{'from'} }
sub length { $_[0]->{'string'}->length }

sub reset_display {
    $_[0]->{'display'} =
	{
	 'type'     => 'sequence',
	 'label1'   => $_[0]->{'id'},
	 'sequence' => $_[0]->{'string'},
	 'range'    => [],
	};
    $_[0];
}

sub get_color {
    my ($self, $c, $map) = @_;
    my ($index, $color, $trans);

    #set transparent(T)/solid(S)
    if (exists $Bio::MView::Align::Colormaps->{$map}->{$c}) {

	$trans = $Bio::MView::Align::Colormaps->{$map}->{$c}->[1];
	$index = $Bio::MView::Align::Colormaps->{$map}->{$c}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$c $map\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }	

    #wildcard colour
    if (exists $Bio::MView::Align::Colormaps->{$map}->{'*'}) {

	$trans = $Bio::MView::Align::Colormaps->{$map}->{'*'}->[1];
	$index = $Bio::MView::Align::Colormaps->{$map}->{'*'}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$c $map\{'*'} [$index] [$color] [$trans]\n";

	return ($color, "C${index}-$trans");
    }

    return 0;    #no match
}

sub color_by_type {
    my $self = shift;
    my %par = @_;

    $par{'css1'}     = 0
	unless defined $par{'css1'};
    $par{'symcolor'} = $Bio::MView::Align::Colour_Black
	unless defined $par{'symcolor'};
    $par{'gapcolor'} = $Bio::MView::Align::Colour_Black
	unless defined $par{'gapcolor'};
    $par{'colormap'} = $Bio::MView::Align::Default_Alignment_Colormap
	unless defined $par{'colormap'};
    $par{'colormap2'}= $Bio::MView::Align::Default_Consensus_Colormap
	unless defined $par{'colormap2'};

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});
    
    push @$color, 1, $self->length, 'color' => $par{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);
	
	#warn "[$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap: gapcolour
	if ($self->{'string'}->is_non_sequence($c)) {
	    push @$color, $i, 'color' => $par{'gapcolor'};
	    next;
	}
	
	#use symbol color/wildcard colour
	@tmp = $self->get_color($c, $par{'colormap'});
	
	if (@tmp) {
	    if ($par{'css1'}) {
		push @$color, $i, 'class' => $tmp[1];
	    } else {
		push @$color, $i, 'color' => $tmp[0];
	    }
	} else {
	    push @$color, $i, 'color' => $par{'symcolor'};
	}
    }
    
    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub color_by_identity {
    my ($self, $othr) = (shift, shift);
    my %par = @_;

    return unless $othr;

    die "${self}::color_by_identity() length mismatch\n"
	unless $self->length == $othr->length;

    $par{'css1'}     = 0
	unless defined $par{'css1'};
    $par{'symcolor'} = $Bio::MView::Align::Colour_Black
	unless defined $par{'symcolor'};
    $par{'gapcolor'} = $Bio::MView::Align::Colour_Black
	unless defined $par{'gapcolor'};
    $par{'colormap'} = $Bio::MView::Align::Default_Alignment_Colormap
	unless defined $par{'colormap'};
    $par{'colormap2'}= $Bio::MView::Align::Default_Consensus_Colormap
	unless defined $par{'colormap2'};

    my ($color, $end, $i, $c1, $c2, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $par{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c1 = $self->{'string'}->raw($i); $c2 = $othr->{'string'}->raw($i);

	#warn "[$i]= $c1 <=> $c2\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c1);
					 
	#gap: gapcolour
	if ($self->{'string'}->is_non_sequence($c1)) {
	    push @$color, $i, 'color' => $par{'gapcolor'};
	    next;
	}

	#same symbol when upcased: use symbol/wildcard color
	if (uc $c1 eq uc $c2) {

            @tmp = $self->get_color($c1, $par{'colormap'});

	    if (@tmp) {
		if ($par{'css1'}) {
		    push @$color, $i, 'class' => $tmp[1];
		} else {
		    push @$color, $i, 'color' => $tmp[0];
		}
	    } else {
		push @$color, $i, 'color' => $par{'symcolor'};
	    }

	    next;
	}

	#different symbol: use contrast colour
	#push @$color, $i, 'color' => $par{'symcolor'};
	
	#different symbol: use wildcard colour
	@tmp = $self->get_color('*', $par{'colormap'});
	if (@tmp) {
	    if ($par{'css1'}) {
		push @$color, $i, 'class' => $tmp[1];
	    } else {
		push @$color, $i, 'color' => $tmp[0];
	    }
	} else {
	    push @$color, $i, 'color' => $par{'symcolor'};
	}
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub set_identity {
    my $self = shift;
    my $ref = shift;
    my $val = $self->compute_identity_to($ref);
    $self->set_display('label4'=>sprintf("%.1f%%", $val));
}

#compute percent identity to input reference object over length of aligned
#region of reference (same as blast). The latter is actually calculated by
#looking at the length of self, minus any terminal gaps.
sub compute_identity_to {
    my $self = shift;
    my $othr = shift;
    my ($end, $i, $c1, $c2, $sum, $len, $gap);

    return unless $othr;

    die "${self}::compute_identity_to() length mismatch\n"
	unless $self->length == $othr->length;
    
    $end = $self->length +1;
    $sum = $len = 0;

    for ($i=1, $gap=0; $i<$end; $i++, $gap=0) {

	$c1 = $self->{'string'}->raw($i); $c2 = $othr->{'string'}->raw($i);
	
	$gap++  if $self->{'string'}->is_non_sequence($c1);
	$gap++  if $self->{'string'}->is_non_sequence($c2);
	
	next    if $gap > 1;
	
	#zero or at most one gap:

	#ignore leader/trailer gaps
	$len++  unless $self->{'string'}->is_padding($c1);

	$sum++  if $c1 eq $c2;
    }
    
    #warn "identity $self->{'id'} = $sum/$len\n";

    $sum = 100 * ($sum + 0.0) / $len    if $len > 0;
    $sum;
}

#compute percent identity to input reference object over length of aligned
#region of reference (same as blast). The latter is actually calculated by
#looking at the length of self, minus any terminal gaps.
sub find_identical_to {
    my $self = shift;
    my $othr = shift;
    my ($end, $i, $c1, $c2, $sum, $len, $gap, $s, $new);

    return unless $othr;

    die "${self}::find_identical_to() length mismatch\n"
	unless $self->length == $othr->length;
    
    $end = $self->length +1;
    $sum = $len = 0;
    $s   = '';

    for ($i=1, $gap=0; $i<$end; $i++, $gap=0) {

	$c1 = $self->{'string'}->raw($i); $c2 = $othr->{'string'}->raw($i);

	$gap++  if $self->{'string'}->is_non_sequence($c1);
	$gap++  if $self->{'string'}->is_non_sequence($c1);

	if ($gap > 1) {
	    $s .= $Bio::MView::Sequence::Text_Spc;
	    next;
	}

	#zero or at most one gap:

	#ignore leader/trailer gaps
	$len++  unless $self->{'string'}->is_padding($c1);

	if ($c1 ne $c2) {
	    $s .= $Bio::MView::Sequence::Text_Spc;
	    next;
	}

	$s .= $c1;
	$sum++;
    }

    $sum = 100 * ($sum + 0.0) / $len    if $len > 0;
   
    #encode the new "sequence"
    $new = new Bio::MView::Sequence;
    $new->append([\$s, $self->{'from'}, $self->{'from'}+$end-2]);

    #return a new identity Row therefrom
    Bio::MView::Align::Identity->new($self->id, $othr->id, $new, $sum);
}


###########################################################################
1;
