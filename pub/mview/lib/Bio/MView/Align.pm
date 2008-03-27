# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Align.pm,v 1.22 1999/11/22 16:06:02 nbrown Exp $

######################################################################
package Bio::MView::Align;

use Bio::MView::Sequence;
use Bio::MView::Display;
use Bio::MView::Align::Row;

use strict;

use vars qw($Default_PRO_Alignment_Colormap $Default_PRO_Consensus_Colormap 
            $Default_DNA_Alignment_Colormap $Default_DNA_Consensus_Colormap
	    $Default_Alignment_Colormap $Default_Consensus_Colormap
	    $Colour_White $Colour_Black $Colour_Cream
            $Colour_DarkGray $Colour_LightGray $Colormaps $Palette $Map_Text);

$Default_PRO_Alignment_Colormap = 'P1';     	  #default colormap name
$Default_PRO_Consensus_Colormap = 'PC1';  	  #default colormap name
$Default_DNA_Alignment_Colormap = 'D1';     	  #default colormap name
$Default_DNA_Consensus_Colormap = 'DC1';  	  #default colormap name

$Default_Alignment_Colormap     = $Default_PRO_Alignment_Colormap;
$Default_Consensus_Colormap     = $Default_PRO_Consensus_Colormap;

$Colour_Black   	    	= '#000000';      #black
$Colour_DarkGray    	    	= '#666666';      #dark gray
$Colour_LightGray   	    	= '#999999';      #light gray
$Colour_Cream            	= '#FFFFCC';      #off-white/cream
$Colour_White   	    	= '#FFFFFF';      #white

$Colormaps                  	= {};             #static hash of colormaps
$Palette                        = [{},[]];        #static color palette
$Map_Text                       = '';             #used as special index

my %Template = 
    (
     'length'     => 0,     #alignment width
     'id2index'   => undef, #hash of identifiers giving row numbers
     'index2row'  => undef, #ordered list by row number of aligned objects
     'parent'     => undef, #identifier of of parent sequence
     'cursor'     => -1,    #index2row iterator
     'ref_id'     => undef, #identifier of reference row
     'tally'      => undef, #column tallies for consensus
     'coloring'   => undef, #coloring mode
     'colormap'   => undef, #name of colormap
     'colormap2'  => undef, #name of second colormap
     'group'      => undef, #consensus group name
     'ignore'     => undef, #ignore self/non-self classes
     'con_gaps'   => undef, #ignore gaps when computing consensus
     'threshold'  => undef, #consensus threshold for colouring
     'bold'       => undef, #display alignment in bold
     'css1'       => undef, #use CSS1 style sheets
     'alncolor'   => undef, #colour of alignment background
     'symcolor'   => undef, #default colour of alignment text
     'gapcolor'   => undef, #colour of alignment gap
     'old'        => {},    #previous settings of the above
     'nopshash'   => undef, #hash of id's to ignore for computations/colouring
     'hidehash'   => undef, #hash of id's to ignore for display
    );

my %Known_Parameter = 
    (
     'ref_id'     => [ '\S+',     undef ],
     'coloring'   => [ '\S+',     'none' ], 
     'colormap'   => [ '\S+',     $Default_Alignment_Colormap ],
     'colormap2'  => [ '\S+',     $Default_Alignment_Colormap ],
     'bold'       => [ '[01]',    1 ],
     'css1'       => [ '[01]',    0 ],
     'alncolor'   => [ '\S+',     $Colour_White    ],
     'symcolor'   => [ '\S+',     $Colour_Black    ],
     'gapcolor'   => [ '\S+',     $Colour_DarkGray ],
     'group'      => [ '\S+',     $Bio::MView::Align::Consensus::Default_Group ],
     'ignore'     => [ '\S+',     $Bio::MView::Align::Consensus::Default_Ignore ],
     'con_gaps'   => [ '[01]',    1 ],
     'threshold'  => [ [],        [80] ],
     'nopshash'   => [ {},        {} ],
     'hidehash'   => [ {},        {} ],
    );

my %Known_Molecule_Type =
    (
     #name
     'aa'         => 1,    #protein
     'na'         => 1,    #DNA/RNA
    );

my %Known_Alignment_Colors =
    (
     #name
     'none'       => 1,
     'any'        => 1,
     'identity'   => 1,
     'consensus'  => 1,
     'group'      => 1,
    );

my %Known_Consensus_Colors =
    (
     #name
     'none'       => 1,
     'any'        => 1,
     'identity'   => 1,
    );


#static load the $Colormaps hash
load_colormaps();


sub new {
    my $type = shift;
    #warn "${type}::new() @_\n";
    if (@_ < 1) {
	die "${type}::new() missing arguments\n";
    }
    my ($obj, $parent) = (@_, undef);
    my $i;

    my %self = %Template;

    $self{'id2index'}  = {};
    $self{'index2row'} = [];

    for ($i=0; $i<@$obj; $i++) {

	if (defined $obj->[$i]) {

	    #warn "[$i] ",  $obj->[$i]->id, " ", $obj->[$i]->string, "\n";

	    $self{'id2index'}->{$obj->[$i]->id} = $i;
	    $self{'index2row'}->[$i] = $obj->[$i];

	    $self{'length'} = $obj->[$i]->length    if $self{'length'} < 1;
	    
	    if ($obj->[$i]->length != $self{'length'}) {
		die "${type}::new() incompatible alignment lengths, row $i, expect $self{'length'}, got @{[$obj->[$i]->length]}\n";
	    }

	}
    }

    if (defined $parent) {
	$self{'parent'} = $parent;
    } else {
	$self{'parent'} = $self{'index2row'}->[0];
    } 

    my $self = bless \%self, $type;
    $self->initialise_parameters;
    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    my $self = shift;
    local $_;
    foreach (sort keys %$self) {
	printf "%15s => %s\n", $_, (defined $self->{$_}?$self->{$_}:'undef');
    }
    foreach (@{$self->{'index2row'}}) {
	$_->print    if defined $_;
    }
    print "\n";
    $self;
}

sub initialise_parameters {
    my $self = shift;
    my ($p) = (@_, \%Known_Parameter);
    local $_;
    foreach (keys %$p) {
	#warn "initialise_parameters() $_\n";
	if (ref $p->{$_}->[0] eq 'ARRAY') {
	    $self->{$_} = [];
	    next;
	}
	if (ref $p->{$_}->[0] eq 'HASH') {
	    $self->{$_} = {};
	    next;
	}
	$self->{$_} = $p->{$_}->[1];
    }

    $self->{'nopshash'} = {};
    $self->{'hidehash'} = {};

    $self;
}

sub set_parameters {
    my $self = shift;
    my $p = ref $_[0] ? shift : \%Known_Parameter;
    my ($key, $val);
    #warn "set_parameters($self) ". join(" ", keys %$p), "\n";
    while ($key = shift) {
	$val = shift;
	#warn "set_parameters() $key, $val\n";
	if (exists $p->{$key}) {
	    #warn "set_parameters() $key, $val\n";
	    if (ref $p->{$key}->[0] eq 'ARRAY' and ref $val eq 'ARRAY') {
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    if (ref $p->{$key}->[0] eq 'HASH' and ref $val eq 'HASH') {
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    if (! defined $val) {
		#set default
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $p->{$key}->[1];
		next;
	    }
	    if ($val =~ /^$p->{$key}->[0]$/) {
		#matches expected format
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    warn "${self}::set_parameters() bad value for '$key', got '$val', wanted '$p->{$key}->[0]'\n";
	}
	#ignore unrecognised parameters which may be recognised by subclass
	#set_parameters() methods.
	#warn "set_parameters(IGNORE) $key, $val\n";
    }

    $self;
}

#concatenate Align object Rows into a new Align object: can be used to copy
sub cat {
    my $self = $_[0];
    my $i;
    my @obj = ();
    foreach (@_) {
	for ($i=0; $i<@{$_->{'index2row'}}; $i++) {
	    next unless defined $_->{'index2row'}->[$i];
	    push @obj, $_->{'index2row'}->[$i];
	}
    }
    new Bio::MView::Align(\@obj, $self->{'parent'});
}

sub length { $_[0]->{'length'} }

#return list of identifiers
sub ids {
    my @id = ();
    foreach (@{$_[0]->{'index2row'}}) {
	push @id, $_->id    if defined $_;
    }
    @id;
}

#return list of visible identifiers
sub visible { 
    my @id = ();
    foreach (@{$_[0]->{'index2row'}}) {
	push @id, $_->id
	    if defined $_ and ! exists $_[0]->{'hidehash'}->{$_->id};
    }
    @id;
}

#return number of stored rows
sub rows   { scalar map { $_->id if defined $_ } @{$_[0]->{'index2row'}} };

#return row object indexed by identifier
sub item {
    my ($self, $id) = @_;
    return 0    unless defined $id;
    if (exists $self->{'id2index'}->{$id}) {
	return $self->{'index2row'}->[$self->{'id2index'}->{$id}];
    }
    0;
}

#delete row(s) by identifier
sub delete {
    my $self = shift;
    local $_;
    foreach (@_) {
	$self->{'index2row'}->[$self->{'id2index'}->{$_}] = undef;
	$self->{'id2index'}->{$_} = undef;
    }
    $self;
}

#initialise stream of row objects
sub reset { $_[0]->{'cursor'} = -1 }

#return next row object in stream, or return 0 and reinitialise
sub next {
    $_[0]->{'cursor'}++;
    if (defined $_[0]->{'index2row'}->[$_[0]->{'cursor'}]) {
	return $_[0]->{'index2row'}->[$_[0]->{'cursor'}];
    }
    $_[0]->{'cursor'} = -1;
    return 0;
}

#load colormap data from stream
sub load_colormaps {
    my ($stream) = (@_, \*DATA);
    my ($state, $map, $transparent, $de) = (0);
    local $_;
    while (<$stream>) {

	#comments, blank lines
	if (/^\s*\#/ or /^\s*$/) {
	    next  if $state != 1;
	    $de .= $_;
	    next;
	}

	#map [name]
	if (/^\s*\[\s*(\S+)\s*\]/) {
	    $map = uc $1;
	    $state = 1;
	    $de = '';
	    next;
	}

	die "Bio::MView::Align::load_colormaps(): color mapname undefined\n"
	    unless defined $map;

	#save map description?
	$Colormaps->{$map}->{$Map_Text} = $de  if $state == 1;

	#symbol [symbol] ->|=> RGB code
	if (/^\s*(\S)(\S)?\s*(->|=>)\s*(\#[0123456789ABCDEF]{6})(?:\s*(.*))?/i)
	{
	    $state = 2;
	    $transparent = ($3 eq '->' ? 'T' : 'S');
	    $de = (defined $5 ? $5 : '');
	    #warn "hex  |$4| ($transparent)\n";
	    if (! exists $Palette->[0]->{$4}) {
		push @{$Palette->[1]}, $4;
		$Palette->[0]->{$4} = $#{$Palette->[1]};
	    }
	    $Colormaps->{$map}->{$1} = [$Palette->[0]->{$4}, $transparent, $de];
	    $Colormaps->{$map}->{$2} = [$Palette->[0]->{$4}, $transparent, $de]
		if defined $2;
	    next;
	}

	#symbol [symbol] ->|=> colorname
	if (/^\s*(\S)(\S)?\s*(->|=>)\s*([^\#\s]+)(?:\s+(.*))?/) {
	    $state = 2;
	    $transparent = ($3 eq '->' ? 'T' : 'S');
	    $de = (defined $5 ? $5 : '');
	    #warn "name |$4|\n";
	    if (! exists $Palette->[0]->{$4}) {
		push @{$Palette->[1]}, $4;
		$Palette->[0]->{$4} = $#{$Palette->[1]};
	    }
	    $Colormaps->{$map}->{$1} = [$Palette->[0]->{$4}, $transparent, $de];
	    $Colormaps->{$map}->{$2} = [$Palette->[0]->{$4}, $transparent, $de]
		if defined $2;
	    next;
	}
	#default
	chomp; die "Bio::MView::Align::load_colormaps(): bad format in line '$_'\n";	
    }
    close $stream;
}

#return a descriptive listing of all known colormaps
sub list_colormaps {
    my $html = shift;
    my ($map, $sym, %p, $u, $l, $pal);
    my ($s, $f1, $f2) = ('', '', '');

    $s .= "#Colormap listing - suitable for reloading.\n";
    $s .= "#Character matching is case-sensitive.\n\n";
    
    @_ = keys %$Colormaps  unless @_;

    foreach $map (sort @_) {
	$s .= "[$map]\n";
	$s .= $Colormaps->{$map}->{$Map_Text};
	$s .= "#symbols =>  color           [#comment]\n";

	%p = %{$Colormaps->{$map}};    #copy colormap structure

	foreach $sym (sort keys %p) {

	    next    if $sym eq $Map_Text;
	    next    unless exists $p{$sym} and defined $p{$sym};

	    ($u, $l) = (uc $sym, lc $sym);

	    $pal = $Palette->[1]->[ $p{$sym}->[0] ];

	    ($f1, $f2) = ("<FONT COLOR=\"$pal\">", "</FONT>")  if $html;

	    #lower and upper case: same symbol
	    if ($u eq $l) {
		$s .= sprintf("%s%-7s%s  %s  %s%-15s%s %s%s%s\n",
			      $f1, $sym, $f2,
			      ($p{$sym}->[1] eq 'T' ? '->' : '=>'),
			      $f1, $pal, $f2,
			      $f1, $p{$sym}->[2], $f2);
		next;
	    }

	    #lower and upper case: two symbols
	    if (exists $p{$u} and exists $p{$l}) {

                if ($p{$u}->[0] eq $p{$l}->[0] and
                    $p{$u}->[1] eq $p{$l}->[1]) {

		    #common definition
		    $s .= sprintf("%s%-7s%s  %s  %s%-15s%s %s%s%s\n",
				  $f1, $u . $l, $f2,
				  ($p{$sym}->[1] eq 'T' ? '->' : '=>'),
				  $f1, $pal, $f2,
				  $f1, $p{$sym}->[2], $f2);

		    $p{$u} = $p{$l} = undef;    #forget both

		} else {
		    #different definitions
		    $s .= sprintf("%s%-7s%s  %s  %s%-15s%s %s%s%s\n",
				  $f1, $sym, $f2,
				  ($p{$sym}->[1] eq 'T' ? '->' : '=>'),
				  $f1, $pal, $f2,
				  $f1, $p{$sym}->[2], $f2);
		}
		next;
	    }

	    #default: single symbol
	    $s .= sprintf("%s%-7s%s  %s  %s%-15s%s %s%s%s\n",
			  $f1, $sym, $f2,
			  ($p{$sym}->[1] eq 'T' ? '->' : '=>'),
			  $f1, $pal, $f2,
			  $f1, $p{$sym}->[2], $f2);
	    next;
	}

	$s .= "\n";
    }
    $s;
}

sub print_css1_colormaps {
    my %color = @_;
    my ($s, $i, $col, $fg);

    $color{'alncolor'} = $Known_Parameter{'alncolor'}->[1]
        unless exists $color{'alncolor'};
    $color{'symcolor'} = $Known_Parameter{'symcolor'}->[1]
        unless exists $color{'symcolor'};
    $color{'gapcolor'} = $Known_Parameter{'gapcolor'}->[1]
        unless exists $color{'gapcolor'};
    
    #warn "bg=$color{'alncolor'} fg=$color{'symcolor'}\n";
    
    $s = "TD{font-family:Fixed,Courier,monospace;background-color:$color{'alncolor'};color:$color{'symcolor'};}\n";

    for ($i=0; $i < @{$Palette->[1]}; $i++) {
	
	$col = $Palette->[1]->[$i];
	
	#SOLID: coloured background/monochrome foreground
	#flip foreground between black/white depending on
	#green RGB component of background for contrast - not ideal
	#but it'll do for now.
	$fg = hex(substr($col, 1));
	$fg = ($fg>>16)&255 > 127 ? $Colour_Black : $Colour_White;

	$s .= "FONT.C${i}-S{background-color:$col;color:$fg}\n";

	#TRANSPARENT: no background/coloured foreground
	$s .= "FONT.C${i}-T{color:$col}\n";
    }

    $s;
}

sub check_molecule_type {
    if (defined $_[0]) {
	if (exists $Known_Molecule_Type{lc $_[0]}) {
	    return lc $_[0];
	}
	return undef;
    }
    return map { lc $_ } sort keys %Known_Molecule_Type;
}

sub check_alignment_color_scheme {
    if (defined $_[0]) {
	if (exists $Known_Alignment_Colors{lc $_[0]}) {
	    return lc $_[0];
	}
	return undef;
    }
    return map { lc $_ } sort keys %Known_Alignment_Colors;
}

sub check_consensus_color_scheme {
    if (defined $_[0]) {
	if (exists $Known_Consensus_Colors{lc $_[0]}) {
	    return lc $_[0];
	}
	return undef;
    }
    return map { lc $_ } sort keys %Known_Consensus_Colors;
}

sub check_colormap {
    if (defined $_[0]) {
	if (exists $Colormaps->{uc $_[0]}) {
	    return uc $_[0];
	}
	return undef;
    }
    return sort keys %$Colormaps;
}

sub get_default_colormaps {
    if (! defined $_[0] or $_[0] eq 'aa') {
	#default to protein
	return ($Default_PRO_Alignment_Colormap, $Default_PRO_Consensus_Colormap);
    }
    #otherwise DNA/RNA explicitly requested
    return ($Default_DNA_Alignment_Colormap, $Default_DNA_Consensus_Colormap);
}

#propagate display parameters to row objects
sub set_display {
    my $self = shift;
    local $_;
    foreach (@{$self->{'index2row'}}) {
	if (defined $_) {
	    $_->set_display(@_);
	}
    }
}

#ignore id's in remaining arglist
sub set_identity {
    my $self = shift;
    my $ref  = shift;
    my $nops = shift;

    return unless defined $self->{'id2index'}->{$ref};
    return unless defined $self->{'index2row'}->[$self->{'id2index'}->{$ref}];

    $ref = $self->{'index2row'}->[$self->{'id2index'}->{$ref}];

    foreach (@{$self->{'index2row'}}) {
	if (defined $_ and ! exists $nops->{$_->id}) {
	    $_->set_identity($ref);
	}
    }
}

sub header {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    if ($self->{'coloring'} eq 'any') {
	$s .= "Colored by: property\n";
    }
    elsif ($self->{'coloring'} eq 'identity' and defined $self->{'ref_id'}) {
	$s .= "Colored by: identity + property\n";
    }
    elsif ($self->{'coloring'} eq 'consensus') {
	$s .= "Colored by: consensus/$self->{'threshold'}->[0]\% and property\n";
    }
    elsif ($self->{'coloring'} eq 'group') {
	$s .= "Colored by: consensus/$self->{'threshold'}->[0]\% and group property\n";
    }
    Bio::MView::Display::displaytext($s);
}

sub set_color_scheme {
    my $self = shift;

    $self->set_parameters(@_);
    
    if ($self->{'coloring'} eq 'any') {
	$self->color_by_type('colormap'  => $self->{'colormap'},
			     'colormap2' => $self->{'colormap2'},
			     'symcolor'  => $self->{'symcolor'},
			     'gapcolor'  => $self->{'gapcolor'},
			     'css1'      => $self->{'css1'},
			    );
	return $self;
    }
    
    if ($self->{'coloring'} eq 'identity') {
	$self->color_by_identity($self->{'ref_id'},
				 'colormap'  => $self->{'colormap'},
				 'colormap2' => $self->{'colormap2'},
				 'symcolor'  => $self->{'symcolor'},
				 'gapcolor'  => $self->{'gapcolor'},
				 'css1'      => $self->{'css1'},
				);
	return $self;
    }

    if ($self->{'coloring'} eq 'consensus') {
	$self->color_by_consensus_sequence('colormap'  => $self->{'colormap'},
					   'colormap2' => $self->{'colormap2'},
					   'group'     => $self->{'group'},
					   'threshold' => $self->{'threshold'},
					   'symcolor'  => $self->{'symcolor'},
					   'gapcolor'  => $self->{'gapcolor'},
					   'css1'      => $self->{'css1'},
					  );
	return $self;
    }

    if ($self->{'coloring'} eq 'group') {
	$self->color_by_consensus_group('colormap'  => $self->{'colormap'},
					'colormap2' => $self->{'colormap2'},
					'group'     => $self->{'group'},
					'threshold' => $self->{'threshold'},
					'symcolor'  => $self->{'symcolor'},
					'gapcolor'  => $self->{'gapcolor'},
					'css1'      => $self->{'css1'},
				       );
	return $self;
    }

    return $self    if $self->{'coloring'} eq 'none';

    warn "${self}::set_color_scheme() unknown mode '$self->{'coloring'}'\n";

    $self;
}

#propagate colour scheme to row objects
sub color_by_type {
    my $self = shift;
    my $i;
    
    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	next unless defined $self->{'index2row'}->[$i];
	next if exists $self->{'nopshash'}->{$self->{'index2row'}->[$i]->id};
	next if exists $self->{'hidehash'}->{$self->{'index2row'}->[$i]->id};
	$self->{'index2row'}->[$i]->color_by_type(@_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_identity {
    my ($self, $id) = (shift, shift);
    my ($ref, $i);

    $ref = $self->item($id);

    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	next unless defined $self->{'index2row'}->[$i];
	next if exists $self->{'nopshash'}->{$self->{'index2row'}->[$i]->id};
	next if exists $self->{'hidehash'}->{$self->{'index2row'}->[$i]->id};
	$self->{'index2row'}->[$i]->color_by_identity($ref, @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_consensus_sequence {
    my $self = shift;
    my ($con, $i);

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and 
	 $self->{'old'}->{'group'} ne $self->{'group'})) {
	$self->compute_tallies($self->{'group'});
    }

    $con = new Bio::MView::Align::Consensus($self->{'tally'},
					    $self->{'group'},
					    $self->{'threshold'}->[0],
					    $self->{'ignore'},
					    $self->{'parent'}->{'from'});
    
    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	next unless defined $self->{'index2row'}->[$i];
	next if exists $self->{'nopshash'}->{$self->{'index2row'}->[$i]->id};
	next if exists $self->{'hidehash'}->{$self->{'index2row'}->[$i]->id};
	next if $self->{'index2row'}->[$i]->{'class'} eq 'identity';
	$con->color_by_consensus_sequence($self->{'index2row'}->[$i], @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_consensus_group {
    my $self = shift;
    my ($con, $i);

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and 
	 $self->{'old'}->{'group'} ne $self->{'group'})) {

	$self->compute_tallies($self->{'group'});
    }

    $con = new Bio::MView::Align::Consensus($self->{'tally'},
					    $self->{'group'},
					    $self->{'threshold'}->[0],
					    $self->{'ignore'},
					    $self->{'parent'}->{'from'});
    
    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	next unless defined $self->{'index2row'}->[$i];
	next if exists $self->{'nopshash'}->{$self->{'index2row'}->[$i]->id};
	next if exists $self->{'hidehash'}->{$self->{'index2row'}->[$i]->id};
	next if $self->{'index2row'}->[$i]->{'class'} eq 'identity';
	$con->color_by_consensus_group($self->{'index2row'}->[$i], @_);
    }
    $self;
}

#return array of Bio::MView::Display::display() constructor arguments
sub init_display { ( $_[0]->{'parent'}->{'string'} ) }

#append Row data to the input Display object: done one at a time to 
#reduce memory usage instead of accumulating a potentially long list before
#passing to Display::append(), and to permit incremental garbage collection of
#each Align::Row object oce it has been appended. the latter can be switched
#off if optional argument $nogc is true (needed when further processing of Row
#objects will occur, eg., consensus calculations).
sub append_display {
    my ($self, $dis, $nogc) = (@_, 0);
    my $i;
    #warn "append_display($dis, $nogc)\n";
    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	if (defined $self->{'index2row'}->[$i]) {
	    next  if
		exists $self->{'hidehash'}->{$self->{'index2row'}->[$i]->id};
	    
	    #append the row data structure to the Display object
	    $dis->append($self->{'index2row'}->[$i]->get_display);

	    #optional garbage collection
	    $self->{'index2row'}->[$i] = undef  unless $nogc;
	}
    }
    $self;
}

#compute effective all pairwise alignment and keep only those sequences
#with pairwise identity <= $limit. also keep any sequences with id's
#supplied as remaining arguments.
sub prune_all_identities_gt {
    my ($self, $limit, $topn) = (shift, shift, shift);
    my (@obj, %keep, $ref, $i, $row);

    @obj = ();

    #special case
    return $self    if $limit >= 100;

    #ensure no replicates in keep list
    foreach $i (@_) {
	$ref = $self->{'index2row'}->[$self->{'id2index'}->{$i}];
	$keep{$ref} = $ref    if defined $ref;
    }

    #prime keep list
    @obj = ();

    #compare all rows not on keep list against latter and add thereto if
    #sufficiently dissimilar
    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	
	next unless defined $self->{'index2row'}->[$i];

	#enforce limit on number of rows
	last    if $topn > 0 and @obj == $topn;

	if (exists $keep{$self->{'index2row'}->[$i]}) {
	    push @obj, $self->{'index2row'}->[$i];
	    next;
	}

	$row = $self->{'index2row'}->[$i];
	
	foreach $ref (@obj) {
	    #store object if %identity satisfies cutoff for all kept hits
	    if ($row->compute_identity_to($ref) > $limit) {
		$row = 0;
		last;
	    }
	}
	
	if ($row) {
	    #print STDERR "passed ", $row->id, "\n";
	    push @obj, $row;
	}

	#warn join(" ", map { $_->id } @obj), "\n";
    }

    new Bio::MView::Align(\@obj, $self->{'parent'});
}

#generate a new alignment from an existing one with extra information
#showing %identities and identical symbols with respect to some supplied
#identifier. only keep lines  with %identity to reference <= $limit.
sub prune_identities_gt {
    my ($self, $id, $limit) = @_;
    my ($ref, $i, @obj, $row, $val);
    
    $ref = $self->item($id);

    @obj = ();

    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {

	next unless defined $self->{'index2row'}->[$i];

	$row = $self->{'index2row'}->[$i];

	#store object if %identity satisfies cutoff OR if the object was
	#the reference object!
	if (($val = $row->compute_identity_to($ref)) <= $limit or
	     $row->id eq $id) {

	    $row->set_display('label4'=>sprintf("%.1f%%", $val));
	
	    push @obj, $row;
	}
    }

    new Bio::MView::Align(\@obj, $self->{'parent'});
}

#generate a new alignment from an existing one with lines showing
#%identities and identical symbols with respect to some supplied identifier
#interpolated between the original aligned items.
sub add_identity_rows {
    my ($self, $id, $invert) = (@_, 0);
    my ($ref, $i, @obj, $old, $ide);

    $ref = $self->item($id);

    @obj = ();

    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {

	next unless defined $self->{'index2row'}->[$i];

	$old = $self->{'index2row'}->[$i];

	if (exists $self->{'nopshash'}->{$old->id}) {
	    push @obj, $old;
	    next;
	}

	next    if exists $self->{'hidehash'}->{$old->id};
	
	$ide = $old->find_identical_to($ref);

	$ide->set_display('label1'=>'',
			  'label4'=>sprintf("%.1f%%", $ide->get_identity),
			  'pad'=>' ');
	
	if ($invert) {
	    push @obj, $ide, $old;
	} else {
	    #default is to place identities under self
	    push @obj, $old, $ide;
	}
    }

    new Bio::MView::Align(\@obj, $self->{'parent'})->set_parameters('nopshash' => $self->{'nopshash'}, 'hidehash' => $self->{'hidehash'});
}

#generate a new alignment comprising a ruler based on this alignment
sub build_ruler {
    new Bio::MView::Align([new Bio::MView::Align::Ruler($_[0]->length)],
			  $_[0]->{'parent'});
}

#generate a new alignment using an existing one but with lines showing
#consensus sequences at specified percent thresholds
sub build_consensus_rows {
    my ($self, $group, $threshold, $ignore, $con_gaps) = @_;
    my ($thresh, $con, $i);
    
    $self->set_parameters('group' => $group, 'ignore' => $ignore,
			  'con_gaps' => $con_gaps);

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and 
	 $self->{'old'}->{'group'} ne $self->{'group'})) {

	$self->compute_tallies($self->{'group'});
    }

    my @obj = ();
    
    foreach $thresh (@$threshold) {

	$con = new Bio::MView::Align::Consensus($self->{'tally'},
						$group, $thresh, $ignore,
						$self->{'parent'}->{'from'});

	$con->set_display('label0'=>'',
			  'label2'=>'',
			  'label3'=>'',
			  'label4'=>'');
	
	push @obj, $con;
    }

    new Bio::MView::Align(\@obj, $self->{'parent'});
}

sub compute_tallies {
    my ($self, $group) = @_;
    my ($row, $col, $r, $c);

    $group = $Bio::MView::Align::Consensus::Default_Consensus
	unless defined $group;

    $self->{'tally'} = [];

    #iterate over columns
    for ($c=1; $c <= $self->{'length'}; $c++) {

	$col = [];

	#iterate over rows
	for ($r=0; $r<@{$self->{'index2row'}}; $r++) {

	    $row = $self->{'index2row'}->[$r];
	    
	    next unless defined $row;
	    next if exists $self->{'nopshash'}->{$row->id};
	    next if exists $self->{'hidehash'}->{$row->id};
	    next if $row->{'class'} eq 'identity';

	    push @$col, $row->{'string'}->raw($c);
	}

	#warn "compute_tallies: @$col\n";

	push @{$self->{'tally'}},
	    Bio::MView::Align::Consensus::tally($group, $col,
						$self->{'con_gaps'});
    }
    $self;
}


######################################################################
1;

__DATA__
#netscape 216 cross-platform colours

#symbol -> colour (RGB hex or colorname)  [#comment]

[P1]
#protein: highlight amino acid physicochemical properties
Gg  =>  #33cc00    #hydrophobic       (bright green)
Aa  =>  #33cc00    #hydrophobic       (bright green)
Ii  =>  #33cc00    #hydrophobic       (bright green)
Vv  =>  #33cc00    #hydrophobic       (bright green)
Ll  =>  #33cc00    #hydrophobic       (bright green)
Mm  =>  #33cc00    #hydrophobic       (bright green)
Ff  =>  #009900    #large hydrophobic (dark green)
Yy  =>  #009900    #large hydrophobic (dark green)
Ww  =>  #009900    #large hydrophobic (dark green)
Hh  =>  #009900    #large hydrophobic (dark green)
Cc  =>  #ffff00    #cysteine          (yellow)
Pp  =>  #33cc00    #hydrophobic       (bright green)
Kk  =>  #cc0000    #positive charge   (bright red)
Rr  =>  #cc0000    #positive charge   (bright red)
Dd  =>  #0033ff    #negative charge   (bright blue)
Ee  =>  #0033ff    #negative charge   (bright blue)
Qq  =>  #6600cc    #polar             (purple)
Nn  =>  #6600cc    #polar             (purple)
Ss  =>  #0099ff    #small alcohol     (dull blue)
Tt  =>  #0099ff    #small alcohol     (dull blue)
Bb  =>  #666666    #D or N            (dark grey)
Zz  =>  #666666    #E or Q            (dark grey)
Xx  =>  #666666    #any               (dark grey)
?   =>  #999999    #unknown           (light grey)
*   =>  #666666    #mismatch          (dark grey)

[GPCR]
#protein: GPCRdb color scheme for Gert Vriend
Gg  =>  #cc6600    #backbone change   (orange brown)
Pp  =>  #cc6600    #backbone change   (orange brown)
Aa  =>  #33cc00    #hydrophobic       (bright green)
Ii  =>  #33cc00    #hydrophobic       (bright green)
Vv  =>  #33cc00    #hydrophobic       (bright green)
Ll  =>  #33cc00    #hydrophobic       (bright green)
Mm  =>  #33cc00    #hydrophobic       (bright green)
Cc  =>  #ffff00    #cysteine          (yellow)
Qq  =>  #cc0000    #positive charge   (bright red)
Ee  =>  #cc0000    #positive charge   (bright red)
Nn  =>  #cc0000    #positive charge   (bright red)
Dd  =>  #cc0000    #positive charge   (bright red)
Bb  =>  #cc0000    #D or N            (bright red)
Zz  =>  #cc0000    #E or Q            (bright red)
Hh  =>  #0033ff    #negative charge   (bright blue)
Kk  =>  #0033ff    #negative charge   (bright blue)
Rr  =>  #0033ff    #negative charge   (bright blue)
Ss  =>  #33cccc    #small alcohol     (dark green-blue)
Tt  =>  #33cccc    #small alcohol     (dark green-blue)
Yy  =>  #00ffcc    #large hydrophobic (medium green-blue)
Ff  =>  #00ffff    #large hydrophobic (light green-blue)
Ww  =>  #00ffff    #large hydrophobic (light green-blue)
Xx  =>  #666666    #any               (dark grey)
?   =>  #999999    #unknown           (light grey)
*   =>  #666666    #mismatch          (dark grey)

[CYS]
#protein: highlight cysteines
Cc  =>  #ffff00    #cysteine (yellow)
Xx  =>  #666666    #any      (dark grey)
?   =>  #999999    #unknown  (light grey)
*   =>  #666666    #mismatch (dark grey)

[CHARGE]
#protein: highlight charged amino acids
Kk  =>  #cc0000    #positive charge (bright red)
Rr  =>  #cc0000    #positive charge (bright red)
Dd  =>  #0033ff    #negative charge (bright blue)
Ee  =>  #0033ff    #negative charge (bright blue)
Bb  =>  #666666    #D or N          (dark grey)
Zz  =>  #666666    #E or Q          (dark grey)
Xx  =>  #666666    #any             (dark grey)
?   =>  #999999    #unknown         (light grey)
*   =>  #666666    #mismatch        (dark grey)

[POLAR1]
#protein: highlight charged and polar amino acids
Kk  =>  #cc0000    #positive charge (bright red)
Rr  =>  #cc0000    #positive charge (bright red)
Dd  =>  #0033ff    #negative charge (bright blue)
Ee  =>  #0033ff    #negative charge (bright blue)
Qq  =>  #6600cc    #charged/polar   (purple)
Nn  =>  #6600cc    #charged/polar   (purple)
Ss  =>  #6600cc    #charged/polar   (purple)
Tt  =>  #6600cc    #charged/polar   (purple)
Hh  =>  #6600cc    #charged/polar   (purple)
Bb  =>  #6600cc    #D or N          (purple)
Zz  =>  #6600cc    #E or Q          (purple)
Xx  =>  #666666    #any             (dark grey)
?   =>  #999999    #unknown         (light grey)
*   =>  #666666    #mismatch        (dark grey)

[D1]
#DNA: highlight purine versus pyrimidine
Aa  =>  #0033ff    #purine             (bright blue)
Gg  =>  #0033ff    #purine             (bright blue)
Tt  =>  #0099ff    #pyrimidine         (dull blue)
Cc  =>  #0099ff    #pyrimidine         (dull blue)
Uu  =>  #0099ff    #pyrimidine         (dull blue)
Mm  =>  #666666    #A or C             (dark grey)
Rr  =>  #666666    #A or G             (dark grey)
Ww  =>  #666666    #A or T             (dark grey)
Ss  =>  #666666    #C or G             (dark grey)
Yy  =>  #666666    #C or T             (dark grey)
Kk  =>  #666666    #G or T             (dark grey)
Vv  =>  #666666    #A or C or G; not T (dark grey)
Hh  =>  #666666    #A or C or T; not G (dark grey)
Dd  =>  #666666    #A or G or T; not C (dark grey)
Bb  =>  #666666    #C or G or T; not A (dark grey)
Nn  =>  #666666    #A or C or G or T   (dark grey)
Xx  =>  #666666    #any                (dark grey)
?   =>  #999999    #unknown            (light grey)
*   =>  #666666    #mismatch           (dark grey)

[D2]
#DNA: highlight match versus mismatch under consensus coloring schemes
*   =>  #cc0000    #mismatch  (red)
?   =>  #999999    #unknown   (light grey)
Aa  =>  #0033ff    #match     (blue)
Bb  =>  #0033ff    #match     (blue)
Cc  =>  #0033ff    #match     (blue)
Dd  =>  #0033ff    #match     (blue)
Gg  =>  #0033ff    #match     (blue)
Hh  =>  #0033ff    #match     (blue)
Kk  =>  #0033ff    #match     (blue)
Mm  =>  #0033ff    #match     (blue)
Nn  =>  #0033ff    #match     (blue)
Rr  =>  #0033ff    #match     (blue)
Ss  =>  #0033ff    #match     (blue)
Tt  =>  #0033ff    #match     (blue)
Uu  =>  #0033ff    #match     (blue)
Vv  =>  #0033ff    #match     (blue)
Ww  =>  #0033ff    #match     (blue)
Xx  =>  #0033ff    #match     (blue)
Yy  =>  #0033ff    #match     (blue)

[PC1]
#protein consensus: highlight equivalence class
a  ->  #009900    #aromatic        (dark green)
l  ->  #33cc00    #aliphatic       (bright green)
h  ->  #33cc00    #hydrophobic     (bright green)
+  ->  #cc0000    #positive charge (bright red)
-  ->  #0033ff    #negative charge (bright blue)
c  ->  #6600cc    #charged         (purple)
p  ->  #0099ff    #polar           (dull blue)
o  ->  #0099ff    #alcohol         (dull blue)
u  ->  #33cc00    #tiny            (bright green)
s  ->  #33cc00    #small           (bright green)
t  ->  #33cc00    #turnlike        (bright green)
*  ->  #666666    #mismatch        (dark grey)

[DC1]
#DNA consensus: highlight ring type
r  ->  #6600cc    #purine     (purple)
y  ->  #ff3333    #pyrimidine (orange)
*  ->  #666666    #mismatch   (dark grey)


##########################################################################
