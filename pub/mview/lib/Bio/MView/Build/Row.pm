# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Row.pm,v 1.3 1999/04/28 18:21:14 nbrown Exp $

###########################################################################
package Bio::MView::Build::Row;

use vars qw($Default_TextWidth);
use Bio::MView::Sequence;
use strict;

$Default_TextWidth = 30;    #default width to truncate 'text' field

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq) = (@_, undef);
    my $self = {};

    bless $self, $type;

    $self->{'rid'}  = $id;                      #supplied identifier
    $self->{'uid'}  = $self->uniqid($num, $id); #unique compound identifier

    #strip non-identifier leading rubbish:  >  or /:
    $id =~ s/^(>|\/:)//;

    #ensure identifier is non-null (for Build::map_id())
    $id = ' '  unless $id =~ /./;

    $self->{'num'}  = $num;                     #row number/string
    $self->{'cid'}  = $id;                      #cleaned identifier
    $self->{'desc'} = $desc;                    #description string
    $self->{'frag'} = [];                       #list of fragments

    $self->{'seq'}  = new Bio::MView::Sequence; #finished sequence

    $self->add_frag($seq)    if defined $seq;

    $self->{'url'}  = Bio::SRS::srsLink($self->{'cid'});  #url

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

#methods returning standard strings for use in generic output modes
sub rid  { $_[0]->{'rid'} }
sub uid  { $_[0]->{'uid'} }
sub cid  { $_[0]->{'cid'} }
sub num  { $_[0]->{'num'} }
sub url  { $_[0]->{'url'} }
sub sob  { $_[0]->{'seq'} }

sub seq  {
    return $_[0]->{'seq'}->string    if defined $_[0]->{'seq'};
    return '';
}

sub desc { $_[0]->{'desc'} }

sub data { '' }

sub text {
    my $w = defined $_[1] ? $_[1] : $Default_TextWidth;
    $w = length $_[0]->{'desc'}    if (defined $w && defined $_[0]->{'desc'} &&
				       $w > length $_[0]->{'desc'});
    sprintf("%-${w}s", $_[0]->truncate($_[0]->{'desc'}, $w));
}

sub uniqid { "$_[1]\034/$_[2]" }

sub print {
    map { warn sprintf "%20s => '%s'\n", $_, $_[0]->{$_} } keys %{$_[0]};
}

sub truncate {
    my ($self, $s, $n, $t) = (@_, $Default_TextWidth);
    $t = substr($s, 0, $n);
    substr($t, -3, 3) = '...'    if length $s > $n;
    $t;
}

#routine to sort 'frag' list: default is null
sub sort {$_[0]}

#add a sequence fragment to the 'frag' list with value and positions given
#by first three args. use default positions if called with one arg. other
#optional arguments are special to any subclass of Row.
sub add_frag {
    my $self = shift;
    my ($frag, $qry_from, $qry_to) = (shift, shift, shift);

    $qry_from = 1               unless defined $qry_from;
    $qry_to   = length $frag    unless defined $qry_to;

    push @{$self->{'frag'}}, [ \$frag, $qry_from, $qry_to, @_ ];

    #warn "@{$self->{'frag'}->[ $#{$self->{'frag'}} ]}\n";

    $self;
}

sub count_frag { scalar @{$_[0]->{'frag'}} }

#compute the maximal positional range of a row
sub range {
    my ($self, $orient) = (@_, '+');
    return $self->range_plus    if $orient =~ /^\+/;
    return $self->range_minus;
}

#compute the maximal positional range of a forward row (numbered forwards)
sub range_plus {
    my $self = shift;
    my ($lo, $hi, $frag);

    return (0, 0)    unless @{$self->{'frag'}};

    $lo = $hi = $self->{'frag'}->[0]->[1];

    foreach $frag (@{$self->{'frag'}}) {
	$lo = ($frag->[1] < $lo ? $frag->[1] : $lo);
	$hi = ($frag->[2] > $hi ? $frag->[2] : $hi);
    }
    #warn "range_plus ($lo, $hi)\n";
    ($lo, $hi);
}

#compute the maximal positional range of a reversed row (numbered backwards)
sub range_minus {
    my $self = shift;
    my ($lo, $hi, $frag);

    return (0, 0)    unless @{$self->{'frag'}};

    $lo = $hi = $self->{'frag'}->[0]->[1];

    foreach $frag (@{$self->{'frag'}}) {
	$lo = ($frag->[2] < $lo ? $frag->[2] : $lo);
	$hi = ($frag->[1] > $hi ? $frag->[1] : $hi);
    }
    #warn "range_minus ($lo, $hi)\n";
    ($lo, $hi);
}

sub assemble {
    my ($self, $lo, $hi, $gap, $reverse) = (@_, 0);
    $self->sort;                                   #worst to best fragments
    $self->{'seq'}->reverse    if $reverse;        #before calling append() !
    $self->{'seq'}->append(@{$self->{'frag'}});    #assemble fragments
    $self->{'seq'}->set_range($lo, $hi);           #set sequence range
    $self->{'seq'}->set_pad($gap);
    $self->{'seq'}->set_gap($gap);
    $self;
}

sub set_pad { $_[0]->{'seq'}->set_pad($_[1]) }
sub set_gap { $_[0]->{'seq'}->set_gap($_[1]) }
sub set_spc { $_[0]->{'seq'}->set_spc($_[1]) }

sub rdb {
    my ($self, $mode) = (@_, 'data');
    if ($mode eq 'data') {
	return join "\t", $self->num, $self->cid, $self->url, $self->seq, $self->desc;
    }
    if ($mode eq 'attr') {
	return join "\t", 'num', 'cid', 'url', 'seq', 'desc';
    }
    if ($mode eq 'form') {
	return join "\t", '4N', '30S', '100S', '500S', '500S';
    }
    '';
}

sub pearson {
    my $self = shift;
    my ($s, $p, $i) = ($self->seq);
    $p = ">" . $self->rid . " " . $self->desc . "\n";
    for ($i=0; $i<length($s); $i+=70) {
        $p .= substr($s, $i, 70) . "\n";
    }
    $p;
}

sub pir {
    my $self = shift;
    my ($s, $p, $i) = ($self->seq, '');
    for ($i=0; $i<length($s); $i+=60) {
	$p .= "\n" . substr($s, $i, 60);
    }
    $p .= "\n"    if length($p) % 61 < 1 and $p ne '';
    $p .= "*\n";
    $p  = ">P1;" . $self->rid . "\n" . $self->desc . $p;
}


###########################################################################
1;
