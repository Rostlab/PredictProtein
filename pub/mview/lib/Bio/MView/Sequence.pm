# Copyright (c) 1997-1999  Nigel P. Brown. \$Id$

###########################################################################
package Bio::MView::Sequence;

use strict;
use vars qw($Find_Pad $Find_Gap $Find_Spc
	    $Text_Pad $Text_Gap $Text_Spc
	    $Mark_Pad $Mark_Gap $Mark_Spc);

$Find_Pad = '[._-]';
$Find_Gap = '[._-]';
$Find_Spc = '\s';

$Text_Pad = '.';
$Text_Gap = '-';
$Text_Spc = ' ';

$Mark_Pad = "\001";    #leading/trailing non-sequence
$Mark_Gap = "\002";    #internal gap
$Mark_Spc = "\003";    #internal white space
   
#all range numbers count from 1, set to 0 when undefined.
sub new {
    my $type = shift;
    my $self = {};

    $self->{'seq'}    	= {};   	#sparse array
    
    $self->{'lo'}     	= 0;    	#absolute start of string
    $self->{'hi'}     	= 0;    	#absolute end of string
    
    $self->{'prefix'} 	= 0;    	#length of non-sequence prefix
    $self->{'suffix'} 	= 0;    	#length of non-sequence suffix
    
    $self->{'seqbeg'} 	= 0;    	#first position of sequence data
    $self->{'seqend'} 	= 0;    	#last  position of sequence data

    $self->{'find_pad'} = $Find_Pad;
    $self->{'find_gap'} = $Find_Gap;
    $self->{'find_spc'} = $Find_Spc;
    
    $self->{'text_pad'} = $Text_Pad;
    $self->{'text_gap'} = $Text_Gap;
    $self->{'text_spc'} = $Text_Spc;
    
    bless $self, $type;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    my $self = shift;
    warn "$self\n";
    map { warn "$_\t=>  $self->{$_}\n" } keys %$self;
    warn "seq=[", $self->string, "]\n";
    $self;
}

sub encode {
    my ($self, $s) = @_;

    #leading non-sequence characters
    while ($$s =~ s/^($Mark_Pad*)$self->{'find_gap'}/$1$Mark_Pad/g) {}
    
    #trailing non-sequence characters
    while ($$s =~ s/$self->{'find_gap'}($Mark_Pad*)$/$Mark_Pad$1/g) {}
    
    #internal gap characters
    $$s =~ s/$self->{'find_gap'}/$Mark_Gap/g;

    #internal spaces
    $$s =~ s/$self->{'find_spc'}/$Mark_Spc/g;

    $self;
}

#return effective sequence length given by lower/upper bounds
sub length {
    return $_[0]->{'hi'} - $_[0]->{'lo'} + 1    if $_[0]->{'lo'} > 0;
    return 0;
}

#return positive oriented begin/end positions
sub lo { $_[0]->{'lo'} }
sub hi { $_[0]->{'hi'} }

#return real oriented begin/end positions
sub from { $_[0]->{'lo'} }
sub to   { $_[0]->{'hi'} }

#return lengths of leading/trailing terminal gap regions
sub leader  { my $n = $_[0]->{'seqbeg'} - $_[0]->{'lo'}; $n > -1 ? $n : 0 }
sub trailer { my $n = $_[0]->{'hi'} - $_[0]->{'seqend'}; $n > -1 ? $n : 0 }

sub set_find_pad { $_[0]->{'find_pad'} = $_[1] }
sub set_find_gap { $_[0]->{'find_gap'} = $_[1] }
sub set_find_spc { $_[0]->{'find_spc'} = $_[1] }

sub set_pad { $_[0]->{'text_pad'} = $_[1] }
sub set_gap { $_[0]->{'text_gap'} = $_[1] }
sub set_spc { $_[0]->{'text_spc'} = $_[1] }

sub get_pad { $_[0]->{'text_pad'} }
sub get_gap { $_[0]->{'text_gap'} }
sub get_spc { $_[0]->{'text_spc'} }

sub set_range {
    my ($self, $lo, $hi) = @_;
    die "$self: range values in wrong order ($lo, $hi)\n"    if $lo > $hi;
    ($self->{'lo'}, $self->{'hi'}) = ($lo, $hi);
    $self;
}

sub is_reversed {0}

sub reverse {
    no strict qw(subs);
    bless $_[0], Bio::MView::Reversed_Sequence;
}

sub string { $_[0]->substr($_[0]->{'lo'}, $_[0]->{'hi'}) }

#input each argument frag as [string, from, to], where from <= to
sub append {
    my $self = shift;
    my ($string, $frag, $len, $i, $p, $c, $state);

    $state = 0;

    foreach $frag (@_) {

	$string = ${$frag->[0]};

        #warn "+frg=$frag->[1], $frag->[2] [$string]\n";

	die "${self}::append() wrong direction ($frag->[1], $frag->[2])\n"
	    if $frag->[1] > $frag->[2];

	$self->encode(\$string);

	#warn "frg=$frag->[1], $frag->[2] [$string]\n";

	$len = CORE::length $string;
	
        #update sequence range
        $self->{'lo'} = $frag->[1] 
	    if $frag->[1] < $self->{'lo'} || $self->{'lo'} < 1;
        $self->{'hi'} = $frag->[2]
	    if $frag->[2] > $self->{'hi'} || $self->{'hi'} < 1;

	#populate sparse array, replacing any existing character
	for ($i=0; $i < $len; $i++) {

	    $c = substr($string, $i, 1);

	    #begin/end
	    if ($c eq $Mark_Pad) {
		if ($state == 0) {
		    $self->{'prefix'}++;
		} elsif ($state > 0) {
		    $self->{'suffix'}++;
		    $state = 2;
		}
		next;
	    }

	    #middle
	    $state = 1    if $state < 1;

	    #skip gaps
	    next    if $c eq $Mark_Gap;

	    $p = $frag->[1] + $i;
	    
	    #warn "$p/($self->{'lo'},$self->{'hi'}) = $i/$len\t[$c]\n";

	    #store other text, including Mark_Spc space symbols
	    $self->{'seq'}->{$p} = $c;
	}

	#warn "append: $self->{'lo'} $self->{'hi'}\n";
    }

    #adjust prefix/suffix positions given new lengths
    $self->{'seqbeg'} = $self->{'lo'} + $self->{'prefix'};
    $self->{'seqend'} = $self->{'hi'} - $self->{'suffix'};

    $self;
}

sub substr {
    my ($self, $start, $len) = (@_, 1);
    my ($s, $i, $stop) = ('');

    return $s    if $start < 1 or $len < 0;    #negative range args
    
    $stop = $start + $len -1;

    return $s    unless $self->{'lo'} > 0;     #empty
    return $s    if $stop  < $self->{'lo'};    #missed (too low)
    return $s    if $start > $self->{'hi'};    #missed (too high)

    $stop = $self->{'hi'}    if $stop > $self->{'hi'};
    $stop++;
    
    for ($i = $start; $i < $stop; $i++) {
	if ($i < $self->{'seqbeg'} or $i > $self->{'seqend'}) {
	    $s .= $self->{'text_pad'};
	    next;
	}
	$s .= exists $self->{'seq'}->{$i} ?
	    $self->{'seq'}->{$i} : $self->{'text_gap'};
    }
    $s =~ s/$Mark_Spc/$self->{'text_spc'}/g;
    $s;
}

sub raw {
    my ($self, $col, $map) = @_;

    $map = $col + $self->{'lo'} -1;

    return ''    if $map < $self->{'lo'};
    return ''    if $map > $self->{'hi'};

    return $Mark_Pad
	if $map < $self->{'seqbeg'} or $map > $self->{'seqend'};
    return $self->{'seq'}->{$map}
        if exists $self->{'seq'}->{$map};
    return $Mark_Gap;
}

sub col {
    my ($self, $col, $map) = @_;

    $map = $col + $self->{'lo'} -1;

#    warn("$col [", 
#	 exists $self->{'seq'}->{$col} ? $self->{'seq'}->{$col} : '',
#	 "]=> $map [", 
#	 exists $self->{'seq'}->{$map} ? $self->{'seq'}->{$map} : '',
#	 "]\n");
    
    return ''    if $map < $self->{'lo'};
    return ''    if $map > $self->{'hi'};

    return $self->{'text_pad'}
	if $map < $self->{'seqbeg'} or $map > $self->{'seqend'};
    return ($self->{'seq'}->{$map} ne $Mark_Spc ? 
	    $self->{'seq'}->{$map} : $self->{'text_spc'})
        if exists $self->{'seq'}->{$map};
    return $self->{'text_gap'};
}

#space symbol
sub is_space        { $_[1] eq $Mark_Spc }

#sequence character
sub is_sequence     {
    $_[1] ne $Mark_Pad and $_[1] ne $Mark_Gap and $_[1] ne $Mark_Spc;
}

#leader/trailer padding symbol or gap symbol or space
sub is_non_sequence {
    $_[1] eq $Mark_Pad or $_[1] eq $Mark_Gap or $_[1] eq $Mark_Spc;
}

#leader/trailer padding symbol
sub is_padding      { $_[1] eq $Mark_Pad }


###########################################################################
package Bio::MView::Reversed_Sequence;

use Bio::MView::Sequence;

use vars qw(@ISA);
use strict;

@ISA = qw(Bio::MView::Sequence);

#return real oriented begin/end positions
sub from { $_[0]->{'hi'} }
sub to   { $_[0]->{'lo'} }

sub is_reversed {1}

sub reverse {
    no strict qw(subs);
    bless $_[0], Bio::MView::Sequence;
}

#input each argument frag as [string, from, to], where from >= to
sub append {
    my $self = shift;
    my ($string, $frag, $len, $i, $p, $c, $state);

    $state = 0;

    foreach $frag (@_) {

	$string = ${$frag->[0]};

        #warn "-frg=$frag->[1], $frag->[2] [$string]\n";

        die "${self}::append() wrong direction ($frag->[1], $frag->[2])\n"
	    if $frag->[2] > $frag->[1];

	$self->encode(\$string);
	#warn "frg=$frag->[1], $frag->[2] [$string]\n";

	$len = length $string;
	
        #dynamically determine sequence range REVERSE
        $self->{'lo'} = $frag->[2] 
	    if $frag->[2] < $self->{'lo'} || $self->{'lo'} < 1;
        $self->{'hi'} = $frag->[1]
	    if $frag->[1] > $self->{'hi'} || $self->{'hi'} < 1;

	#populate sparse array, replacing any existing character
	for ($i=0; $i < $len; $i++) {

	    $c = substr($string, $i, 1);

	    #begin/end
	    if ($c eq $Bio::MView::Sequence::Mark_Pad) {
		if ($state == 0) {
		    $self->{'prefix'}++;
		} elsif ($state > 0) {
		    $self->{'suffix'}++;
		    $state = 2;
		}
		next;
	    }

	    #middle
	    $state = 1    if $state < 1;

	    #skip gaps
	    next    if $c eq $Bio::MView::Sequence::Mark_Gap;

	    $p = $frag->[1] - $i;    #REVERSE
	    
	    #warn "$p/($self->{'lo'},$self->{'hi'}) = $i/$len\t[$c]\n";

	    #store other text, including Mark_Spc space symbols
	    $self->{'seq'}->{$p} = $c;
	}
	
	#warn "append: $self->{'lo'} $self->{'hi'}\n";
    }

    #adjust prefix/suffix positions given new lengths
    $self->{'seqbeg'} = $self->{'lo'} + $self->{'prefix'};
    $self->{'seqend'} = $self->{'hi'} - $self->{'suffix'};

    $self;
}

sub substr {
    my ($self, $start, $len) = (@_, 1);
    my (@a, $i, $stop, $s) = ();

    return ''    if $start < 1 or $len < 0;    #negative range args
    
    $stop = $start + $len -1;

    return ''    unless $self->{'lo'} > 0;     #empty
    return ''    if $stop  < $self->{'lo'};    #missed (too low)
    return ''    if $start > $self->{'hi'};    #missed (too high)

    $stop = $self->{'hi'}    if $stop > $self->{'hi'};
    $stop++;

    for ($i = $start; $i < $stop; $i++) {

	if ($i < $self->{'seqbeg'} or $i > $self->{'seqend'}) {
	    push @a, $self->{'text_pad'};
	    next;
	}
	push @a, exists $self->{'seq'}->{$i} ? 
	    $self->{'seq'}->{$i} : $self->{'text_gap'};
    }
    $s = join '', CORE::reverse @a;
    $s =~ s/$Bio::MView::Sequence::Mark_Spc/$self->{'text_spc'}/g;
    $s;
}

sub raw {
    my ($self, $col, $map) = @_;

    $map = $self->{'hi'} - $col +1;    #REVERSE $col

    return ''    if $map < $self->{'lo'};
    return ''    if $map > $self->{'hi'};

    return $Bio::MView::Sequence::Mark_Pad
	if $map < $self->{'seqbeg'} or $map > $self->{'seqend'};
    return $self->{'seq'}->{$map}
        if exists $self->{'seq'}->{$map};
    return $Bio::MView::Sequence::Mark_Gap;
}

sub col {
    my ($self, $col, $map) = @_;

    $map = $self->{'hi'} - $col +1;    #REVERSE $col
    
#    warn("$col [", 
#	 exists $self->{'seq'}->{$col} ? $self->{'seq'}->{$col} : '',
#	 "]=> $map [", 
#	 exists $self->{'seq'}->{$map} ? $self->{'seq'}->{$map} : '',
#	 "]\n");

    return ''    if $map < $self->{'lo'};
    return ''    if $map > $self->{'hi'};

    return $self->{'text_pad'}
	if $map < $self->{'seqbeg'} or $map > $self->{'seqend'};
    return ($self->{'seq'}->{$map} ne $Bio::MView::Sequence::Mark_Spc ? 
	    $self->{'seq'}->{$map} : $self->{'text_spc'})
        if exists $self->{'seq'}->{$map};
    return $self->{'text_gap'};
}


###########################################################################
1;
