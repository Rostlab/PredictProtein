# -*- perl -*-
# Copyright (c) 1999  Nigel P. Brown. \$Id: MIPS.pm,v 1.1 1999/05/13 14:40:07 nbrown Exp $

###########################################################################
package Parse::Format::MIPS;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


#delimit full MIPS entry
#my $MIPS_START          = '^\s*(?:\S+)?\s+MIPS:';
#my $MIPS_START          = '^(?:PileUp|\s*(?:\S+)?\s+MIPS:)';
my $MIPS_START          = '^>';
my $MIPS_END            = $MIPS_START;

#MIPS record types
my $MIPS_HEADER         = $MIPS_START;
my $MIPS_HEADERend      = '^L;';
my $MIPS_NAME           = $MIPS_HEADERend;
my $MIPS_NAMEend        = '^C;Alignment';
my $MIPS_ALIGNMENT      = '^\s*\d+';
my $MIPS_ALIGNMENTend   = $MIPS_START;
my $MIPS_Null           = '^\s*$';#'


#Consume one entry-worth of input on stream $fh associated with $file and
#return a new MIPS instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    while (defined ($line = <$fh>)) {

	#start of entry
	if ($line =~ /$MIPS_START/o and $offset < 0) {
	    $offset = $fh->tell - length($line);
	    next;
	}

	#consume rest of stream
	last  if $line =~ /$MIPS_END/o;
    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    new Parse::Format::MIPS(undef, $text, $offset, $bytes);
}
	    
#Parse one entry
sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    while (defined ($line = $text->next_line)) {

	#HEADER lines
	if ($line =~ /$MIPS_HEADER/o) {
	    $text->scan_until($MIPS_HEADERend, 'HEADER');
	    next;
	}
	
	#consume data

	#NAME lines	       	      
	if ($line =~ /$MIPS_NAME/o) {    
	    $text->scan_until($MIPS_NAMEend, 'NAME');
	    next;			       	      
	}				       	      
	
	#ALIGNMENT lines		       	      
	if ($line =~ /$MIPS_ALIGNMENT/o) {       	      
	    $text->scan_until($MIPS_ALIGNMENTend, 'ALIGNMENT');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	next    if $line =~ /$MIPS_Null/o;

	#end of NAME section: ignore
	next    if $line =~ /$MIPS_NAMEend/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::MIPS::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    $self->{'desc'} = '';

    #consume Name lines
    while (defined ($line = $text->next_line)) { 

	#> line
	if ($line =~ /^>[^;]+;(\S+)/o) {
	    $self->test_args($line, $1);
	    $self->{'ac'} = $1;
	    next;
	}
	
	#accumulate other lines
	$self->{'desc'} .= $line;
    }

    $self->warn("missing MIPS data\n")  unless exists $self->{'ac'};

    $self->{'desc'} = Parse::Record::strip_english_newlines($self->{'desc'});

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'ac',     $self->{'ac'};
    printf "$x%20s -> '%s'\n", 'desc',   $self->{'desc'};
}


###########################################################################
package Parse::Format::MIPS::NAME;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    $self->{'seq'}   = {};
    $self->{'order'} = [];
    
    #consume Name lines
    while (defined ($line = $text->next_line)) {

	if ($line =~ /^L;(\S+)\s+(.*)/o) {
	    $self->test_args($line, $1,$2);
	    $self->{'seq'}->{$1} = Parse::Record::strip_english_newlines($2);
	    push @{$self->{'order'}}, $1;
	    next;
	} 
	
	next  if $line =~ /$MIPS_Null/;

	#default
	$self->warn("unknown field: $line");
    }
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    local $_;
    Parse::Record::print $self, $indent;
    foreach (@{$self->{'order'}}) {
	printf "$x%20s -> %-15s %s=%s\n", 
	'seq',    $_,
	'desc',   $self->{'seq'}->{$_};
    }
}


###########################################################################
package Parse::Format::MIPS::ALIGNMENT;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    local $^W=0;
    local $_;
    
    $self->{'seq'} = {};

    while (defined ($line = $text->next_line)) {
    
	no strict;

	#start/end positions
	next  if $line =~ /^\s*\d+[^0-9]*\d+\s*$/o;

	#id/sequence
	if ($line =~ /^\s*(\S+)\s+([^0-9]+)\s+\d+$/o) {
	    $self->test_args($line, $1, $2);
	    $self->{'seq'}->{$1} .= $2;
	    next;
	} 

	#default: ignore all other line types (site and consensus data)
    }

    foreach (keys %{$self->{'seq'}}) {
	$self->{'seq'}->{$_} =~ s/ //g;
    }

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    local $_;
    foreach (keys %{$self->{'seq'}}) {
	printf "$x%20s -> %-15s =  %s\n", 'seq', $_, $self->{'seq'}->{$_};
    }
}


###########################################################################
1;
