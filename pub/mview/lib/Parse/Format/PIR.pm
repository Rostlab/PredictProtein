# -*- perl -*-
# Copyright (c) 1998  Nigel P. Brown. \$Id: PIR.pm,v 1.1 1998/08/24 20:07:16 brown Exp $

###########################################################################
package Parse::Format::PIR;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


#PIR record types
my $PIR_Null     = '^\s*$';#'
my $PIR_SEQ      = '^\s*>';
my $PIR_SEQend   = $PIR_SEQ;


#Consume one entry-worth of input on stream $fh associated with $file and
#return a new Slurp instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    while (defined ($line = <$fh>)) {
	
	#start of entry
	if ($offset < 0) {
            $offset = $fh->tell - length($line);
	    next;
	}

    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    new Parse::Format::PIR(undef, $text, $offset, $bytes);
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
	
	#SEQ lines		       	      
	if ($line =~ /$PIR_SEQ/o) {
	    $text->scan_until($PIR_SEQend, 'SEQ');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	if ($line =~ /$PIR_Null/o) {
	    next;
	}

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::PIR::SEQ;

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

    $self->{'prefix'} = '';
    $self->{'id'}     = '';
    $self->{'desc'}   = '';
    $self->{'seq'}    = '';
    
    while (defined ($line = $text->next_line(1))) {

	#read header line
	if ($line =~ /^\s*>\s*(..);(\S+)/o) {
	    $self->test_args($line, $1, $2);
	    (
	     $self->{'prefix'}, 
	     $self->{'id'}, 
	    ) = ($1, $2);

	    #force read of next line for description
	    $self->{'desc'} = $text->next_line(1);
            $self->{'desc'} = Parse::Record::strip_leading_space($self->{'desc'});
            $self->{'desc'} = Parse::Record::strip_trailing_space($self->{'desc'});

	    next;
	} 

	#read sequence lines upto asterisk, if present
	if ($line =~ /([^\*]+)/) {
	    $self->{'seq'} .= $1;
	    next;
	}

	#ignore lone asterisk
	last    if $line =~ /\*/;

	#default
	$self->warn("unknown field: $line");
	
    }
    #strip internal whitespace from sequence
    $self->{'seq'} =~ s/\s//g;

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'prefix',    $self->{'prefix'};
    printf "$x%20s -> %s\n",   'id',        $self->{'id'};
    printf "$x%20s -> '%s'\n", 'desc',      $self->{'desc'};
    printf "$x%20s -> %s\n",   'seq',       $self->{'seq'};
}


###########################################################################
1;
