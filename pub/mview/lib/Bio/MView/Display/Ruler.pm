# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Ruler.pm,v 1.2 1999/03/18 15:07:03 nbrown Exp $

###########################################################################
package Bio::MView::Display::Ruler;

use Bio::MView::Display::Any;
use vars qw(@ISA);
use strict;

@ISA = qw(Bio::MView::Display::Any);

sub new {
    no strict qw(subs);
    shift;    #discard type
    my $self = new Bio::MView::Display::Any(@_);
    return bless $self, Bio::MView::Display::Reverse_Ruler
	if $self->{'parent'}->{'string'}->is_reversed;
    bless $self, Bio::MView::Display::Forward_Ruler;
}


###########################################################################
package Bio::MView::Display::Forward_Ruler;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Ruler);

sub next {
    my $self = shift;
    my ($html, $bold, $col, $gap, $pad, $lap, $ruler) = @_;
    my ($string, $length, $i, $start, $pos) = ([]);
	 					  
    return 0    if $self->{'cursor'} > $self->{'length'};

    $length = $self->{'length'} - $self->{'cursor'} +1; #length remaining
    $col = $length    if $col > $length;                #consume smaller amount
    $start = $self->{'start'} + $self->{'cursor'} -1;   #current real position

    #warn "($self->{'cursor'}, $col, $length, ($self->{'start'},$self->{'stop'}))\n";

    for ($i = 0; $i < $col; $i++) {

	$pos = $start + $i;     #real data position

	#determine position along ruler
	if ($ruler eq 'abs') {
	    if ($pos == $self->{'start'}) {
		push @$string, '[';
		next;
	    }
	    if ($pos == $self->{'stop'}) {
		push @$string, ']';
		next;
	    }
	} else {
	    die "${self}::next() relative numbering disabled\n";
	}

	#the ruler line
	if ($pos % 100 == 0) {
	    push @$string, substr($pos,-3,1);   #third digit from right
	    next;
	}
	if ($pos % 50 == 0) {
	    push @$string, ':';
	    next;
	}
	if ($pos % 10 == 0) {
	    push @$string, '.';
	    next;
	}
#	if ($pos % 5 == 0) {
#	    push @$string, '.';
#	    next;
#	}
	push @$string, ' ';
    }

    $string= $self->strip_html_repeats($string)    if $html;

    if ($html) {
	unshift @$string, '<STRONG>'           if $bold;
	unshift @$string, $self->{'prefix'}    if $self->{'prefix'};
	push    @$string, $self->{'suffix'}    if $self->{'suffix'};
	push    @$string, '</STRONG>'          if $bold;
    }

    $self->{'cursor'} += $col;

    return [ $start, $pos, join('', @$string) ];
}


###########################################################################
package Bio::MView::Display::Reverse_Ruler;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Ruler);

sub next {
    my $self = shift;
    my ($html, $bold, $col, $gap, $pad, $lap, $ruler) = @_;
    my ($string, $length, $i, $start, $pos) = ([]);
	 					  
    return 0    if $self->{'cursor'} > $self->{'length'};

    $length = $self->{'length'} - $self->{'cursor'} +1; #length remaining
    $col = $length    if $col > $length;                #consume smaller amount
    $start = $self->{'stop'} - $self->{'cursor'} +1;    #current real position

    #warn "($self->{'cursor'}, $col, $length, ($self->{'start'},$self->{'stop'}))\n";

    for ($i = 0; $i < $col; $i++, $self->{'cursor'}++) {

	$pos = $start - $i;     #real data position

	#determine position along ruler
	if ($ruler eq 'abs') {
	    if ($pos == $self->{'start'}) {
		push @$string, ']';
		next;
	    }
	    if ($pos == $self->{'stop'}) {
		push @$string, '[';
		next;
	    }
	} else {
	    die "${self}::next() relative numbering disabled\n";
	}

	#the ruler line
	if ($pos % 100 == 0) {
	    push @$string, substr($pos,-3,1);   #third digit from right
	    next;
	}
	if ($pos % 50 == 0) {
	    push @$string, ':';
	    next;
	}
	if ($pos % 10 == 0) {
	    push @$string, '.';
	    next;
	}
#	if ($pos % 5 == 0) {
#	    push @$string, '.';
#	    next;
#	}
	push @$string, ' ';
    }

    $string= $self->strip_html_repeats($string)    if $html;

    if ($html) {
	unshift @$string, '<STRONG>'           if $bold;
	unshift @$string, $self->{'prefix'}    if $self->{'prefix'};
	push    @$string, $self->{'suffix'}    if $self->{'suffix'};
	push    @$string, '</STRONG>'          if $bold;
    }

    $self->{'cursor'} += $col;

    return [ $start, $pos, join('', @$string) ];
}


###########################################################################
1;
