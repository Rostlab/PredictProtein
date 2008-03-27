# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: fasta.pm,v 1.2 1999/03/09 16:22:31 nbrown Exp $

###########################################################################
package Parse::Format::FASTA1::fasta;

use Parse::Format::FASTA1;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA1);


###########################################################################
package Parse::Format::FASTA1::fasta::HEADER;

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
    
	if ($line =~ /\s*(version\s+(\S+).*)/) {
	    $self->{'full_version'} = $1;
	    $self->{'version'}      = $2;
	}

	if ($line =~ /(\S+)\s*,\s+(\d+)\s+(?:aa|nt)/o) {
	
	    $self->test_args($line, $1, $2);
	    
	    (
	     $self->{'queryfile'},
	     $self->{'length'},
	    ) = ($1, $2);
	    
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
	$self->{'full_version'} = 'looks like FASTA 1';
	$self->{'version'}      = '1?';
    }

    $self;
}


###########################################################################
package Parse::Format::FASTA1::fasta::RANK;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::RANK);

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

    #ranked search hits
    while (defined ($line = $text->next_line)) {
	
	next    if $line =~ /$Parse::Format::FASTA1::RANK_START/o;

	if ($line =~ /^
	    \s*
	    (\S+)                #id
	    \s+
	    (.*)                 #description
	    \s+
	    (\d+)                #initn
	    \s+
	    (\d+)                #init1
	    \s+
	    (\d+)                #opt
	    \s*
	    $/xo) {
	    
	    $self->test_args($line, $1,$2,$3,$4,$5);
	    
	    push @{$self->{'hit'}}, 
	    {
	     'id'    => Parse::Record::strip_leading_identifier_chars($1),
	     'desc'  => $2,
	     'initn' => $3,
	     'init1' => $4,
	     'opt'   => $5,
	    };
	    
	    next;
	}
	 
	#blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::FASTA1::NULL/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::FASTA1::fasta::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::TRAILER);


###########################################################################
package Parse::Format::FASTA1::fasta::HIT;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::HIT);

               
###########################################################################
package Parse::Format::FASTA1::fasta::HIT::SUM;

use vars qw(@ISA);
use Regexps;

@ISA   = qw(Parse::Format::FASTA::HIT::SUM);

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

    $line = $text->next_line;
    
    if ($line =~ /^(\S+)\s+(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/) {
	
	$self->test_args($line, $1, $2, $3, $4, $5);    #ignore $2
	
	(
	 $self->{'id'},
	 $self->{'desc'},
	 $self->{'initn'},
	 $self->{'init1'},
	 $self->{'opt'},
	) = (Parse::Record::strip_leading_identifier_chars($1),
	     Parse::Record::strip_english_newlines($2), $3, $4, $5);
	
    }
    
    $line = $text->next_line;

    if ($line =~ /^\s*($RX_Ureal)\% identity in (\d+) (?:aa|nt) overlap\s*$/) {
	$self->test_args($line, $1, $2);
	(
	 $self->{'id_percent'},
	 $self->{'overlap'},
	)= ($1,$2);
    }
	
    $self;
}


###########################################################################
package Parse::Format::FASTA1::fasta::HIT::ALN;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::HIT::ALN);


###########################################################################
1;
