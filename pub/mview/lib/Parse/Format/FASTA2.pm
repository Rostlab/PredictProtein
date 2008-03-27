# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA2.pm,v 1.5 1999/09/03 20:35:55 nbrown Exp $

###########################################################################
#
# Handles: FASTA   2.x
#          TFASTX  2.x
#
###########################################################################
package Parse::Format::FASTA2;

use Parse::Format::FASTA;
use strict;

use vars qw(
	    @ISA

	    @VERSIONS

	    $NULL

	    $ENTRY_START
	    $ENTRY_END

	    $HEADER_START  
	    $HEADER_END    
	                   
	    $RANK_START 
	    $RANK_END   
	                   
	    $TRAILER_START 
	    $TRAILER_END   
	                   
	    $HIT_START     
	    $HIT_END       
	                   
	    $SUM_START     
	    $SUM_END       
	                   
	    $ALN_START     
	    $ALN_END       
);

@ISA   = qw(Parse::Format::FASTA);

@VERSIONS = ( 
	     '2' => [
		     'FASTA',
		     'TFASTX',
		    ],
	    );

$NULL  = '^\s*$';#for emacs';

$ENTRY_START   = '(?:'
    . '^\s*FASTA searches a protein or DNA sequence data bank'
    . '|'
    . '^\s*TFASTX translates and searches a DNA sequence data bank'
    . '|'
    . '^\s*\S+\s*[,:]\s+\d+\s+(?:aa|nt)'
    . ')';
$ENTRY_END     = 'Library scan:';

$HEADER_START  = $ENTRY_START;
$HEADER_END    = '^The best scores are:'; 
               
$RANK_START    = $HEADER_END;
$RANK_END      = $NULL;
               
$TRAILER_START = $ENTRY_END;
$TRAILER_END   = $ENTRY_END;

$HIT_START     = '^>*\S{7}.*\(\d+ (?:aa|nt)\)';
$HIT_END       = "(?:$HIT_START|$ENTRY_END)";

$SUM_START     = $HIT_START;
$SUM_END       = $NULL;
       
$ALN_START     = '^\s+\d+\s+';    #the ruler
$ALN_END       = $HIT_END;

sub new { my $self=shift; $self->SUPER::new(@_) }


###########################################################################
package Parse::Format::FASTA2::HEADER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::HEADER);

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

    $self->{'query'} = '';

    while (defined ($line = $text->next_line)) {
    
	if ($line =~ /^\s*(version\s+(\S+).*)/) {
	    $self->{'full_version'} = $1;
	    $self->{'version'}      = $2;
	    next;
	}

	if ($line =~ /^\s*([^\s>]+)\s+(\d+)\s+(?:aa|nt)/o) {
	    $self->test_args($line, $1, $2);
	    (
	     $self->{'queryfile'},
	     $self->{'length'},
	    ) = ($1, $2);
	    $self->{'queryfile'} =~ s/,$//;
	    next;
	}

	if ($line =~ /^\s*>(\S+)\s*\:\s*\d+\s+(?:aa|nt)/) {
	    $self->test_args($line, $1);
	    $self->{'query'} = Parse::Record::strip_leading_identifier_chars($1);
	    next;
	}
	
	if ($line =~ /^(\d+)\s+residues\s+in\s+(\d+)\s+sequences/) {
	    
	    $self->test_args($line, $1,$2);
	    
	    (
	     $self->{'residues'},
	     $self->{'sequences'},
	    ) = ($1, $2);

	    next;
	} 

	#ignore any other text

    }

    if (! defined $self->{'full_version'} ) {
	#can't determine version: hardwire one!
	$self->{'full_version'} = 'looks like FASTA 2';
	$self->{'version'}      = '2';
    }

    $self;
}


###########################################################################
1;
