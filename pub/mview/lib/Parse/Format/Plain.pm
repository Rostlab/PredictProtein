# -*- perl -*-
# Copyright (c) 1998  Nigel P. Brown. \$Id: Plain.pm,v 1.2 1999/01/26 23:18:25 nbrown Exp $

######################################################################
#
# The simplest input alignment is a column of id's and a column of aligned
# sequences of identical length with the entire alignment in one block.
#
###########################################################################
package Parse::Format::Plain;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


my $Plain_Null           = '^\s*$';#'
my $Plain_Comment        = '^\s*\#';

#delimit full Plain entry
my $Plain_START          = '\s*[^\#]\S*\s+\S';    #ignore '#' comments
my $Plain_END            = "($Plain_Null|$Plain_Comment)";

#Plain record types
my $Plain_ALIGNMENT      = '^\s*\S+\s+\S';
my $Plain_ALIGNMENTend   = $Plain_END;


#Consume one entry-worth of input on stream $fh associated with $file and
#return a new Plain instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    while (defined ($line = <$fh>)) {

	#start of entry
 	if ($line =~ /$Plain_START/o and $offset < 0) {
	    $offset = $fh->tell - length($line);
	    next;
	}

	#end of entry
        if ($line =~ /$Plain_END/o and ! $offset < 0) {
	    last;
        }
    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    new Parse::Format::Plain(undef, $text, $offset, $bytes);
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

	#consume data

	#comment: ignore
	next    if $line =~ /$Plain_Comment/;

	#ALIGNMENT lines		       	      
	if ($line =~ /$Plain_ALIGNMENT/o) {
	    $text->scan_until($Plain_ALIGNMENTend, 'ALIGNMENT');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	next    if $line =~ /$Plain_Null/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::Plain::ALIGNMENT;

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

	chomp $line;

	#id/sequence
	if ($line =~ /^\s*(\S+)\s+(\S+)\s*$/o) {
	    $self->test_args($line, $1, $2);
	    push @{$self->{'id'}}, $1    unless exists $self->{'seq'}->{$1};
	    $self->{'seq'}->{$1} .= $2;
	    $off = length($line) - length($2);
	    next;
	} 

	#default
	$self->warn("unknown field: $line");
    }

    #line length check (ignore 'match' as this may be missing)
    if (defined $self->{'id'}->[0]) {
	$off = length $self->{'seq'}->{$self->{'id'}->[0]};
	foreach $line (keys %{$self->{'seq'}}) {
	    $line = $self->{'seq'}->{$line};
	    if (length $line != $off) {
		$self->die("unequal line lengths (expect $off, got @{[length $line]})\n");
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
