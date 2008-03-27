# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Consensus.pm,v 1.6 1999/07/30 19:19:49 nbrown Exp $

###########################################################################
package Bio::MView::Align::Consensus;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;
use strict;

use vars qw(@ISA
	    $Default_PRO_Group $Default_DNA_Group
	    $Default_Group_Any $Default_Ignore $Group);

@ISA = qw(Bio::MView::Align::String);

$Default_PRO_Group  = 'P1';       #default consensus scheme name
$Default_DNA_Group  = 'D1';       #default consensus scheme name

$Default_Group_Any  = '.';        #default symbol for non-consensus
$Default_Ignore     = '';         #default ignore classes setting
$Group              = {};         #static hash of consensus schemes


my %Known_Ignore_Class = 
    (
     #name
     'none'       => 1,    #don't ignore
     'singleton'  => 1,    #ignore singleton, ie., self-only consensi
     'class'      => 1,    #ignore non-singleton, ie., class consensi
    );


#static load the $Group hash
load_groupmaps();


sub load_groupmaps {
    my ($stream) = (@_, \*DATA);
    my ($state, $group, $class, $sym, $members, $c, $de) = (0, {}, undef);
    local $_;
    while (<$stream>) {

	#comments, blank lines
	if (/^\s*\#/ or /^\s*$/) {
	    next  if $state != 1;
	    $de .= $_;
	    next;
	}

	#group [name]
	if (/^\s*\[\s*(\S+)\s*\]/) {
	    $group = uc $1;
	    $state = 1;
	    $de = '';
	    next;
	}

	die "Bio::MView::Align::Row::load_groupmaps() groupname undefined\n"    
	    unless defined $group;

	#save map description?
	$Group->{$group}->[3] = $de  if $state == 1;

	#ANY symbol
	if (/^\s*\*\s*=>\s*(\S+|\'[^\']+\')/) {
	    $state = 2;
	    $sym     = $1;
	    $sym     =~ s/^\'//;
	    $sym     =~ s/\'$//;
	    chomp; die "Bio::MView::Align::Row::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    make_group($group, '*', $sym, []);
	}
	
	#general class membership
	if (/^\s*(\S+)\s*=>\s*(\S+|\'[^\']+\')\s*\{\s*(.*)\s*\}/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $2, $3);
	    $sym     =~ s/^\'//;
	    $sym     =~ s/\'$//;
	    chomp; die "Bio::MView::Align::Row::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    $members =~ s/[\s,]//g;
	    $members =~ s/''/ /g;
	    $members = uc $members;
	    $members = [ split(//, $members) ];

	    make_group($group, $class, $sym, $members);

	    next;
	}

	#trivial class self-membership: different symbol
	if (/^\s*(\S+)\s*=>\s*(\S+|\'[^\']+\')/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $2, $1);
	    chomp; die "Bio::MView::Align::Row::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    $members = uc $members;
	    $members = [ split(//, $members) ];

	    make_group($group, $class, $sym, $members);

	    next;
	}

	#trivial class self-membership: same symbol
	if (/^\s*(\S+)/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $1, $1);
	    $members = uc $members;
	    $members = [ split(//, $members) ];

	    make_group($group, $class, $sym, $members);

	    next;
	}

	#default
	chomp; die "Bio::MView::Align::Row::load_groupmaps() bad format in line '$_'\n";	
    }
    close $stream;

    foreach $group (keys %$Group) {
	make_group($group, '*', $Default_Group_Any, [])
	    unless exists $Group->{$group}->[0]->{'*'};
	make_group($group, '', $Bio::MView::Sequence::Mark_Spc,
		   [
		    $Bio::MView::Sequence::Mark_Pad, 
		    $Bio::MView::Sequence::Mark_Gap,
		   ]);
    }
}

sub make_group {
    my ($group, $class, $sym, $members) = @_;
    local $_;

    #class => symbol
    $Group->{$group}->[0]->{$class}->[0] = $sym;
    
    foreach (@$members) {
	#class  => member existence
	$Group->{$group}->[0]->{$class}->[1]->{$_} = 1;
	#member => symbol existence
	$Group->{$group}->[1]->{$_}->{$sym} = 1;
	#symbol => members
	$Group->{$group}->[2]->{$sym}->{$_} = 1;
    }
}

sub dump_group {
    my ($group, $class, $mem, $p);
    push @_, keys %$Group    unless @_;
    warn "Groups by class\n";
    foreach $group (@_) {
	warn "[$group]\n";
	$p = $Group->{$group}->[0];
	foreach $class (keys %{$p}) {
	    warn "$class  =>  $p->{$class}->[0]  { ",
		join(" ", keys %{$p->{$class}->[1]}), " }\n";
	}
    }
    warn "Groups by membership\n";
    foreach $group (@_) {
	warn "[$group]\n";
	$p = $Group->{$group}->[1];
	foreach $mem (keys %{$p}) {
	    warn "$mem  =>  { ", join(" ", keys %{$p->{$mem}}), " }\n";
	}
    }
}

#return a descriptive listing of supplied groups or all groups
sub list_groupmaps {
    my $html = shift;
    my ($group, $class, $p, $sym);
    my $s = '';

    $s .= "#Consensus group listing - suitable for reloading.\n";
    $s .= "#Character matching is case-insensitive.\n";
    $s .= "#Non-consensus positions default to '$Default_Group_Any' symbol.\n";
    $s .= "#Sequence gaps are shown as ' ' (space) symbols.\n\n";
    
    @_ = keys %$Group  unless @_;

    foreach $group (sort @_) {
	$s .= "[$group]\n";
	$s .= $Group->{$group}->[3];
	$s .= sprintf "#%-15s =>  %-6s  %s\n", 'description', 'symbol', 'members';
	$p = $Group->{$group}->[0];
	foreach $class (sort keys %{$p}) {
	    
	    next    if $class eq '';    #gap character

	    #wildcard
	    if ($class eq '*') {
		$sym = $p->{$class}->[0];
		$sym = "'$sym'"    if $sym =~ /\s/;
		$s .= sprintf "%-15s  =>  %-6s\n", $class, $sym;
		next;
	    }
	    
	    #consensus symbol
	    $sym = $p->{$class}->[0];
	    $sym = "'$sym'"    if $sym =~ /\s/;
	    $s .= sprintf "%-15s  =>  %-6s  { ", $class, $sym;
	    $s .= join(", ", sort keys %{$p->{$class}->[1]}) . " }\n";
	}
	$s .= "\n";
    }
    $s;
}

sub check_groupmap {
    if (defined $_[0]) {
	if (exists $Group->{uc $_[0]}) {
	    return uc $_[0];
	}
	return undef;
    }
    return sort keys %$Group;
}

sub check_ignore_class {
    if (defined $_[0]) {
	if (exists $Known_Ignore_Class{lc $_[0]}) {
	    return lc $_[0];
	}
	return undef;
    }
    return map { lc $_ } sort keys %Known_Ignore_Class;
}

sub get_default_groupmap {
    if (! defined $_[0] or $_[0] eq 'aa') {
	#default to protein
	return $Default_PRO_Group;
    }
    #otherwise DNA/RNA explicitly requested
    return $Default_DNA_Group;
}

sub get_color_identity { my $self = shift; $self->SUPER::get_color(@_) }

sub get_color_type {
    my ($self, $c, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_type($self, $c, $mapS, $mapG)\n";

    #look in group colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapG}->{$c}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapG}->{$c}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapG}->{$c}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$c $mapG\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");

    } elsif (exists $Bio::MView::Align::Colormaps->{$mapS}->{$c}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapS}->{$c}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapS}->{$c}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$c $mapS\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }

    #look for wildcard in group only
    if (exists $Bio::MView::Align::Colormaps->{$mapG}->{'*'}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapG}->{'*'}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapG}->{'*'}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$c $mapG\{'*'} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }

    return 0;    #no match
}

sub get_color_consensus_sequence {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_consensus_sequence($self, $cs, $cg, $mapS, $mapG)\n";

    #lookup sequence symbol in sequence colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapS}->{$cs}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapS}->{$cs}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapS}->{$cs}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{$cs} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }
    
    #lookup wildcard in sequence colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapS}->{'*'}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapS}->{'*'}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapS}->{'*'}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{'*'} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }

    return 0;    #no match
}

sub get_color_consensus_group {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_consensus_group($self, $cs, $cg, $mapS, $mapG)\n";

    #lookup group symbol in group colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapG}->{$cg}) {

	#set transparent(T)/solid(S) according to sequence colormap
	if (exists $Bio::MView::Align::Colormaps->{$mapS}->{$cs}) {
	    #use sequence transparency
	    $trans = $Bio::MView::Align::Colormaps->{$mapS}->{$cs}->[1];

	} else {
	    #default to group transparency
	    $trans = $Bio::MView::Align::Colormaps->{$mapG}->{$cg}->[1];

	    #warn "$cs/$cg $mapG\{$cg} [$index] [$color] [$trans]\n";
	}

	$index = $Bio::MView::Align::Colormaps->{$mapG}->{$cg}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{$cs} $mapG\{$cg} [$index] [$color] [$trans]\n";
	return ($color, "C${index}-$trans");
    }
    
    #lookup group symbol in sequence colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapS}->{$cg}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapS}->{$cg}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapS}->{$cg}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{$cg} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }
    
    #lookup wildcard in sequence colormap
    if (exists $Bio::MView::Align::Colormaps->{$mapS}->{'*'}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Align::Colormaps->{$mapS}->{'*'}->[1];
	$index = $Bio::MView::Align::Colormaps->{$mapS}->{'*'}->[0];
	$color = $Bio::MView::Align::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{'*'} [$index] [$color] [$trans]\n";
	
	return ($color, "C${index}-$trans");
    }

    return 0;    #no match
}

sub tally {
    my ($group, $col, $gaps) = (@_, 1);
    my ($score, $class, $sym, $depth) = ({});
    
    if (! exists $Group->{$group}) {
	die "Bio::MView::Align::Consensus::tally() unknown consensus set\n";
    }
    
    #warn "tally: $group\n";

    $group = $Group->{$group}->[0];
    
    #initialise tallies
    foreach $class (keys %$group) { $score->{$class} = 0 }
    
    #select score normalization
    if ($gaps) {
	#by total number of rows (sequence + non-sequence)
	$depth = @$col;
    } else {
	#by rows containing sequence in this column
	$depth = 0;
	map { $depth++ if Bio::MView::Sequence::is_sequence(0, $_) } @$col;
    }

    #empty column? use gap symbol
    if ($depth < 1) {
	$score->{''} = 100;
	return $score;
    }

    #tally class scores by column symbol (except gaps), which is upcased
    foreach $class (keys %$group) {
	foreach $sym (@$col) {
	    next    unless Bio::MView::Sequence::is_sequence(0, $sym) or $gaps;
	    $score->{$class}++    if exists $group->{$class}->[1]->{uc $sym};
	}
	$score->{$class} = 100.0 * $score->{$class} / $depth;
    }
    $score;
}

sub consensus {
    my ($tally, $group, $threshold, $ignore) = @_;
    my ($class, $topclass, $topscore, $consensus, $i, $score);

    if (! exists $Group->{$group}) {
	die "Bio::MView::Align::Consensus::consensus() unknown consensus set\n";
    }
    
    $group = $Group->{$group}->[0];

    $consensus = '';

    #iterate over all columns
    for ($i=0; $i<@$tally; $i++) {
	
	($score, $class, $topclass, $topscore) = ($tally->[$i], "", undef, 0);
	
	#iterate over all allowed subsets
	foreach $class (keys %$group) {
	    
	    next    if $class eq '*'; #wildcard
	    
	    if ($class ne '') {
		#non-gap classes: may want to ignore certain classes
		next if $ignore eq 'singleton' and $class eq $group->{$class}->[0];
		
		next if $ignore eq 'class'     and $class ne $group->{$class}->[0];
	    }
	    
	    #choose smallest class exceeding threshold and
	    #highest percent when same size
	    
	    #warn "[$i] $class, $score->{$class}\n";
	    
	    if ($score->{$class} >= $threshold) {
		
		#first pass
		if (! defined $topclass) {
		    $topclass = $class;
		    $topscore = $score->{$class};
		    next;
		}
		
		#larger? this set should be rejected
		if (keys %{$group->{$class}->[1]} > 
		    keys %{$group->{$topclass}->[1]}) {
		    next;
		}
		
		#smaller? this set should be kept
		if (keys %{$group->{$class}->[1]} <
		    keys %{$group->{$topclass}->[1]}) {
		    $topclass = $class;
		    $topscore = $score->{$class};
		    next;
		} 
		
		#same size: new set has better score?
		if ($score->{$class} > $topscore) {
		    $topclass = $class;
		    $topscore = $score->{$class};
		    next;
		}
	    }
	}
	#warn "DECIDE [$i] '$topclass' $topscore\n";

	if (defined $topclass) {
	    $consensus .= $group->{$topclass}->[0];
	} else {
	    $consensus .= $group->{'*'}->[0];
	}
    }
    \$consensus;
}

sub new {
    my $type = shift;
    #warn "${type}::new() (@_)\n";
    if (@_ < 5) {
	die "${type}::new() missing arguments\n";
    }
    my ($tally, $group, $threshold, $ignore, $from) = @_;

    if ($threshold < 50 or $threshold > 100) {
	die "${type}::new() threshold '$threshold\%' outside valid range [50..100]\n";
    }

    my $self = { %Bio::MView::Align::String::Template };

    $self->{'id'}        = "consensus/$threshold\%";
    $self->{'from'}      = $from;
    $self->{'class'}     = 'consensus';
    $self->{'threshold'} = $threshold;
    $self->{'group'}     = $group;

    my $string = consensus($tally, $group, $threshold, $ignore);

    #encode the new "sequence"
    $self->{'string'} = new Bio::MView::Sequence;
    $self->{'string'}->set_find_gap('\.');
    $self->{'string'}->set_pad('.');
    $self->{'string'}->set_gap('.');
    $self->{'string'}->append([$string,
			       $self->{'from'},
			       $self->{'from'} + length($$string) -1]);
    
    bless $self, $type;

    $self->reset_display;

    $self;
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

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});
    
    push @$color, 1, $self->length, 'color' => $par{'symcolor'};

    #warn "color_by_type($self) 1=$par{'colormap'} 2=$par{'colormap2'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i);
	
	#warn "[$i]= $cg\n";

	#white space: no color
	next    if $self->{'string'}->is_space($cg);

	#gap: gapcolour
	if ($self->{'string'}->is_non_sequence($cg)) {
	    push @$color, $i, 'color' => $par{'gapcolor'};
	    next;
	}
	
	#use symbol color/wildcard colour
	@tmp = $self->get_color_type($cg,
				     $par{'colormap'},
				     $par{'colormap2'});
	
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
    my ($self, $othr) = (shift, shift);    #ignore second arg
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

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $par{'symcolor'};
    
    #warn "color_by_identity($self, $othr) 1=$par{'colormap'} 2=$par{'colormap2'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i);

	#white space: no colour
	next    if $self->{'string'}->is_space($cg);
					 
	#gap: gapcolour
	if ($self->{'string'}->is_non_sequence($cg)) {
	    push @$color, $i, 'color' => $par{'gapcolor'};
	    next;
	}
	
	#consensus group symbol is singleton: choose colour
	if (exists $Group->{$self->{'group'}}->[2]->{$cg}) {
	    if (keys %{$Group->{$self->{'group'}}->[2]->{$cg}} == 1) {

		@tmp = $self->get_color_identity($cg, $par{'colormap'});

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
	}
	
	#symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $par{'symcolor'};
    }
    
    $self->{'display'}->{'paint'} = 1;
    $self;
}

#this is analogous to Bio::MView::Align::Row::String::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_sequence {
    my ($self, $othr) = (shift, shift);
    my %par = @_;

    return unless $othr;
    return if ref($othr) ne 'Bio::MView::Align::String';  #behaviour undefined

    die "${self}::color_by_consensus_sequence() length mismatch\n"
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

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $par{'symcolor'};

    #warn "color_by_consensus_sequence($self, $othr) 1=$par{'colormap'} 2=$par{'colormap2'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";

	#white space: no colour
	next    if $self->{'string'}->is_space($cs);
					 
	#gap: gapcolour
	if ($self->{'string'}->is_non_sequence($cs)) {
	    push @$color, $i, 'color' => $par{'gapcolor'};
	    next;
	}
	
	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
	if (exists $Group->{$self->{'group'}}->[1]->{$c}) {
	    if (exists $Group->{$self->{'group'}}->[1]->{$c}->{$cg}) {

		#colour by sequence symbol
		@tmp = $self->get_color_consensus_sequence($cs, $cg,
							   $par{'colormap'},
							   $par{'colormap2'});

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
	}

        #symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $par{'symcolor'};
    }
    
    $othr->{'display'}->{'paint'} = 1;
    $self;
}


#this is analogous to Bio::MView::Align::Row::String::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_group {
    my ($self, $othr) = (shift, shift);
    my %par = @_;

    return unless $othr;
    return if ref($othr) ne 'Bio::MView::Align::String';  #behaviour undefined

    die "${self}::color_by_consensus_group() length mismatch\n"
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

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});
    
    push @$color, 1, $self->length, 'color' => $par{'symcolor'};

    #warn "color_by_consensus_group($self, $othr) 1=$par{'colormap'} 2=$par{'colormap2'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";
	
	#no consensus symbol
	if ($self->{'string'}->is_space($cg)) {

	    #white space: no colour
	    next    if $self->{'string'}->is_space($cs);

	    #gap: gapcolour
	    if ($self->{'string'}->is_non_sequence($cs)) {
		push @$color, $i, 'color' => $par{'gapcolor'};
		next;
	    }
	}
	
	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
	if (exists $Group->{$self->{'group'}}->[1]->{$c}) {
	    if (exists $Group->{$self->{'group'}}->[1]->{$c}->{$cg}) {

		#colour by consensus group symbol
		#note: both symbols passed; colormaps swapped
		@tmp = $self->get_color_consensus_group($cs, $cg,
							$par{'colormap'},
							$par{'colormap2'});
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
	}
	
	#symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $par{'symcolor'};
    }
    
    $othr->{'display'}->{'paint'} = 1;
    $self;
}

	
###########################################################################
1;

__DATA__
#label      => symbol  { member list }

[P1]
#protein consensus: report conserved physicochemical classes, derived from
#the Venn diagrams of:
# Taylor W. R. (1986). The classification of amino acid conservation.
# J. Theor. Biol. 119:205-218.
#as used in:
# Bork, P., Brown, N.P., Hegyi, H., Schultz, J. (1996). The protein
# phosphatase 2C (PP2C) superfamily: Detection of bacterial homologues.
# Protein Science. 5:1421-1425. 
G
A
I
V
L
M
F
Y
W
H
C
P
K
R
D
E
Q
N
S
T
aromatic    =>   a     { F, Y, W, H }
aliphatic   =>   l     { I, V, L }
hydrophobic =>   h     { I, V, L,   F, Y, W, H,   A, G, M, C, K, R, T }
positive    =>   +     { H, K, R }
negative    =>   -     { D, E }
charged     =>   c     { H, K, R,   D, E }
polar       =>   p     { H, K, R,   D, E,   Q, N, S, T, C }
alcohol     =>   o     { S, T }
tiny        =>   u     { G, A, S }
small       =>   s     { G, A, S,   V, T, D, N, P, C }
turnlike    =>   t     { G, A, S,   H, K, R, D, E, Q, N, T, C }

[D1]
#DNA consensus: report conserved ring types
A
G
C
T
U
purine      =>   r   { A, G }
pyrimidine  =>   y   { C, T, U }

[CYS]
#protein consensus: report conserved cysteines only
C => c


###########################################################################
