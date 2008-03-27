# -*- perl -*-
# Copyright (c) 1998  Nigel P. Brown. \$Id: MSF.pm,v 1.12 1999/05/13 14:40:07 nbrown Exp $

###########################################################################
package Parse::Format::MSF;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


#delimit full MSF entry
#my $MSF_START          = '^\s*(?:\S+)?\s+MSF:';
#my $MSF_START          = '^(?:PileUp|\s*(?:\S+)?\s+MSF:)';
my $MSF_START          = '^(?:PileUp|.*\s+MSF:)';
my $MSF_END            = '^PileUp';

#MSF record types
my $MSF_HEADER         = $MSF_START;
my $MSF_HEADERend      = '^\s*Name:';
my $MSF_NAME           = $MSF_HEADERend;
my $MSF_NAMEend        = '^\/\/';
my $MSF_ALIGNMENT      = '^\s*\S+\s+\S';
my $MSF_ALIGNMENTend   = $MSF_START;
my $MSF_Null           = '^\s*$';#'


#Consume one entry-worth of input on stream $fh associated with $file and
#return a new MSF instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    while (defined ($line = <$fh>)) {

	#start of entry
	if ($line =~ /$MSF_START/o and $offset < 0) {
	    $offset = $fh->tell - length($line);
	    next;
	}

	#consume rest of stream
	last  if $line =~ /$MSF_END/o;
    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    new Parse::Format::MSF(undef, $text, $offset, $bytes);
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
	if ($line =~ /$MSF_HEADER/o) {
	    $text->scan_until($MSF_HEADERend, 'HEADER');
	    next;
	}
	
	#consume data

	#NAME lines	       	      
	if ($line =~ /$MSF_NAME/o) {    
	    $text->scan_until($MSF_NAMEend, 'NAME');
	    next;			       	      
	}				       	      
	
	#ALIGNMENT lines		       	      
	if ($line =~ /$MSF_ALIGNMENT/o) {       	      
	    $text->scan_until($MSF_ALIGNMENTend, 'ALIGNMENT');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	next    if $line =~ /$MSF_Null/o;

	#end of NAME section: ignore
	next    if $line =~ /$MSF_NAMEend/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::MSF::HEADER;

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

	#MSF line
	if ($line =~ /^
	    \s*
	    ((?:.+)?)
	    MSF\:\s+(\d+)
	    \s+
	    Type\:\s+(\S+)
            \s*
	    ((?:.+)?)            
	    Check\:\s+(\d+)
	    \s+\.\.
	    /xo) {

	    $self->test_args($line, $2,$3,$5);
	    (
	     $self->{'file'},
	     $self->{'msf'},
	     $self->{'type'},
             $self->{'data'},
	     $self->{'check'},
	    ) = (Parse::Record::strip_trailing_space($1),
                 $2,$3,
                 Parse::Record::strip_trailing_space($4),
                 $5);
	}
	
	#ignore any other text
    }

    $self->warn("missing MSF data\n")  unless exists $self->{'msf'};

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n", 'file',   $self->{'file'};
    printf "$x%20s -> %s\n",   'msf',    $self->{'msf'};
    printf "$x%20s -> %s\n",   'type',   $self->{'type'};
    printf "$x%20s -> '%s'\n", 'data',   $self->{'data'};
    printf "$x%20s -> %s\n",   'check',  $self->{'check'};
}


###########################################################################
package Parse::Format::MSF::NAME;

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

	if ($line =~ /^
	    \s*
	    Name\:\s+(\S+)    #identifier
	    \s+
	    (?:oo\s+)?        #clustalw makes this. why?
	    Len\:\s+(\d+)     #sequence length
	    \s+
	    Check\:\s+(\d+)   #checksum
	    \s+
	    Weight\:\s+(\S+)  #sequence weight
	    /xo) {

	    $self->test_args($line, $1,$2,$3,$4);
	    $self->{'seq'}->{$1} = 
		{
		 'length' => $2,
		 'check'  => $3,
		 'weight' => $4,
		};
	    push @{$self->{'order'}}, $1;
	    next;
	} 
	
	next  if $line =~ /$MSF_Null/;

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
	printf "$x%20s -> %-15s %s=%5s %s=%5s %s=%5s\n", 
	'seq',    $_,
	'length', $self->{'seq'}->{$_}->{'length'},
	'check',  $self->{'seq'}->{$_}->{'check'},
	'weight', $self->{'seq'}->{$_}->{'weight'};
    }
}


###########################################################################
package Parse::Format::MSF::ALIGNMENT;

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
	next  if $line =~ /^\s*\d+\s+\d+$/o;

	#end position
	next  if $line =~ /^\s*\d+\s*$/o;

	#id/sequence
	if ($line =~ /^\s*(\S+)\s+(.*)$/o) {
	    $self->test_args($line, $1, $2);
	    $self->{'seq'}->{$1} .= $2;
	    next;
	} 

	next  if $line =~ /$MSF_Null/;

	#default
	$self->warn("unknown field: $line");
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
