# -*- perl -*-
# Copyright (c) 1998  Nigel P. Brown. \$Id: CLUSTAL.pm,v 1.8 1999/01/26 23:18:17 nbrown Exp $

###########################################################################
package Parse::Format::CLUSTAL;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


#delimit full CLUSTAL entry
my $CLUSTAL_START          = '^\s*CLUSTAL';
my $CLUSTAL_END            = $CLUSTAL_START;

#CLUSTAL record types
my $CLUSTAL_ALIGNMENT      = '^\s*\S+\s+\S+$';
my $CLUSTAL_ALIGNMENTend   = $CLUSTAL_START;
my $CLUSTAL_HEADER         = $CLUSTAL_START;
my $CLUSTAL_HEADERend      = "(?:$CLUSTAL_ALIGNMENT|$CLUSTAL_HEADER)";
my $CLUSTAL_Null           = '^\s*$';#'


#Consume one entry-worth of input on stream $fh associated with $file and
#return a new CLUSTAL instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    while (defined ($line = <$fh>)) {

	#start of entry
 	if ($line =~ /$CLUSTAL_START/o and $offset < 0) {
	    $offset = $fh->tell - length($line);
	    next;
	}

	#consume rest of stream
        if ($line =~ /$CLUSTAL_END/o) {
	    last;
        }
    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    new Parse::Format::CLUSTAL(undef, $text, $offset, $bytes);
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
	if ($line =~ /$CLUSTAL_HEADER/o) {
	    $text->scan_until($CLUSTAL_HEADERend, 'HEADER');
	    next;
	}
	
	#consume data

	#ALIGNMENT lines		       	      
	if ($line =~ /$CLUSTAL_ALIGNMENT/o) {
	    $text->scan_until($CLUSTAL_ALIGNMENTend, 'ALIGNMENT');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	next    if $line =~ /$CLUSTAL_Null/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::CLUSTAL::HEADER;

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

    #consume Name lines
    while (defined ($line = $text->next_line)) { 

	#first part of CLUSTAL line
	if ($line =~ /^
	    \s*
	    CLUSTAL
	    \s+
	    (([^\(\s]+)    #major version, eg., W
	    \s*
	    \((\S+)\))     #minor version, eg., 1.70
	    /xo) {

	    $self->test_args($line, $1, $2, $3);
	    (
	     $self->{'version'},
	     $self->{'major'},
	     $self->{'minor'},
	    ) = ($1, $2, $3);
	    
	}
	
	#ignore any other text
    }

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'version', $self->{'version'};
    printf "$x%20s -> %s\n",   'major',   $self->{'major'};
    printf "$x%20s -> %s\n",   'minor',   $self->{'minor'};
}


###########################################################################
package Parse::Format::CLUSTAL::ALIGNMENT;

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
    
    $self->{'id'}    = [];
    $self->{'seq'}   = {};
    $self->{'match'} = '';

    my $off = 0;

    while (defined ($line = $text->next_line)) {
    
	no strict;

	chomp $line;

	#match symbols, but only if expected
	if ($off and $line !~ /[^*:. ]/) {
	    $line = substr($line, $off);
	    $self->{'match'} .= $line;
	    $off = 0;
	    next;
	}

	#id/sequence
	if ($line =~ /^\s*(\S+)\s+(\S+)$/o) {
	    $self->test_args($line, $1, $2);
	    push @{$self->{'id'}}, $1    unless exists $self->{'seq'}->{$1};
	    $self->{'seq'}->{$1} .= $2;
	    $off = length($line) - length($2);
	    next;
	} 

	next    if $line =~ /$CLUSTAL_Null/o;

	#default
	$self->warn("unknown field: $line");
    }

    #line length check (ignore 'match' as this may be missing)
    if (defined $self->{'id'}->[0]) {
	$off = length $self->{'seq'}->{$self->{'id'}->[0]};
	foreach $line (keys %{$self->{'seq'}}) {
	    $line = $self->{'seq'}->{$line};
	    if (length $line != $off) {
		$self->die("unequal line lengths (expect $off)\n");
	    }
	}
    }

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    local $_;
    foreach (@{$self->{'id'}}) {
	printf "$x%20s -> %-15s %s\n", 'seq', $_, $self->{'seq'}->{$_};
    }
    printf "$x%20s -> %-15s %s\n", 'match', '', $self->{'match'};
}


###########################################################################
1;
