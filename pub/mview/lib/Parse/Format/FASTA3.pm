# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA3.pm,v 1.4 1999/09/03 20:35:56 nbrown Exp $

###########################################################################
#
# Handles: FASTA   3.x
#          TFASTX  3.x
#
###########################################################################
package Parse::Format::FASTA3;

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
	     '3' => [
		     'FASTA',
		     'TFASTX',
		    ],
	    );

$NULL  = '^\s*$';#for emacs';

$ENTRY_START   = '(?:'
    . '^\s*FASTA searches a protein or DNA sequence data bank'
    . '|'
    . 'TFASTX compares a protein to a translated DNA data bank'
    . '|'
    . '^\s*\S+\s*[,:]\s+\d+\s+(?:aa|nt)'
    . ')';
$ENTRY_END     = 'Function used was\s+FASTA';

$HEADER_START  = $ENTRY_START;
$HEADER_END    = '^The\s+best\s+scores\s+are:';  #3.2t05 added a space!
               
$RANK_START    = $HEADER_END;
$RANK_END      = $NULL;
               
$TRAILER_START = '^\d+\s+residues\s+in\s+\d+\s+query';
$TRAILER_END   = $ENTRY_END;

#$HIT_START     = '^>*\S{7}.*\(\d+ (?:aa|nt)\)';
$HIT_START     = '^>+\S{7}';  #fasta -L flag makes multiple description lines
$HIT_END       = "(?:$HIT_START|$TRAILER_START|$ENTRY_END)";

$SUM_START     = $HIT_START;
$SUM_END       = $NULL;
       
$ALN_START     = '^\s+\d+\s+';    #the ruler
$ALN_END       = $HIT_END;

#Parse one entry: generic for all FASTA3
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

	#Header lines
	if ($line =~ /$HEADER_START/o) {
	    $text->scan_until($HEADER_END, 'HEADER');
	    next;
	}

	#Rank lines		       	      
	if ($line =~ /$RANK_START/o) {
	    $text->scan_until($RANK_END, 'RANK');
	    next;			       	      
	}				       	      
	
	#Hit lines		       	      
	if ($line =~ /$HIT_START/o) {
	    $text->scan_until($HIT_END, 'HIT');
	    next;			       	      
	}

	#Trailer lines
	if ($line =~ /$TRAILER_START/o) {
	    $text->scan_until_inclusive($TRAILER_END, 'TRAILER');
	    next;			       	      
	}
	
	#end of FASTA job
	next    if $line =~ /$ENTRY_END/o;
	
	#blank line or empty record: ignore
	next    if $line =~ /$NULL/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Parse::Format::FASTA3::HEADER;

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
	$self->{'full_version'} = 'looks like FASTA 3';
	$self->{'version'}      = '3';
    }

    $self;
}


###########################################################################
1;
