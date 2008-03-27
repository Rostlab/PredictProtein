# -*- perl -*-
# Copyright (c) 1997-1999  Nigel P. Brown. $Id: Slurp.pm,v 1.9 1999/01/26 23:18:26 nbrown Exp $

###########################################################################
#
# Used to give Parse behaviour to any unformatted stream
#
###########################################################################
package Parse::Format::Slurp;

use vars qw(@ISA);
use strict;

@ISA = qw(Parse::Record);


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

    new Parse::Format::Slurp(undef, $text, $offset, $bytes);
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
    $self;#->examine;
}


###########################################################################
1;
