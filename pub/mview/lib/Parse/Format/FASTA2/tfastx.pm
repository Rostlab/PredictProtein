# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: tfastx.pm,v 1.1 1999/01/26 23:39:05 nbrown Exp $

###########################################################################
package Parse::Format::FASTA2::tfastx;

use Parse::Format::FASTA2;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA2);


###########################################################################
package Parse::Format::FASTA2::tfastx::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA2::HEADER);


###########################################################################
package Parse::Format::FASTA2::tfastx::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::RANK);

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
	
	next    if $line =~ /$Parse::Format::FASTA2::RANK_START/o;

	if($line =~ /^
	   \s*
	   ([^\s]+)                #id
	   \s+
	   (.*)                    #description
	   \s+
	   \((\S)\)                #frame
	   \s+
	   (\d+)                   #initn 
	   \s+
	   (\d+)                   #init1
	   \s+
	   (\d+)                   #opt
	   \s+
	   (\S+)                   #z-score
	   \s+
	   (\S+)                   #E(58765)
	   \s*
	   $/xo) {
	    
	    $self->test_args($line, $1,$2,$3,$4,$5,$6,$7,$8);
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'     => Parse::Record::strip_leading_identifier_chars($1),
		  'desc'   => $2,
		  'frame'  => $3,
		  'initn'  => $4,
		  'init1'  => $5,
		  'opt'    => $6,
		  'zscore' => $7,
		  'expect' => $8,
		 });
	    next;
	}
    
	#blank line or empty record: ignore
	next    if $line =~ /$Parse::Format::FASTA2::NULL/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::FASTA2::tfastx::TRAILER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::TRAILER);


###########################################################################
package Parse::Format::FASTA2::tfastx::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT);


###########################################################################
package Parse::Format::FASTA2::tfastx::HIT::SUM;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::FASTA::HIT::SUM);

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
	
    if ($line =~ /^
	>*
	(\S+)                      #id
	\s+
	(.*)                       #description
	\s+
	\(\s*(\d+)\s*(?:aa|nt)\)   #length
	\s*
	$/xo) {

	$self->test_args($line, $1, $2, $3);

	(
	 $self->{'id'},
	 $self->{'desc'},
	 $self->{'length'},
	) = (Parse::Record::strip_leading_identifier_chars($1),
	     Parse::Record::strip_english_newlines($2), $3);
    } else {
	$self->warn("unknown field: $line");
    }

    $line = $text->next_line;
    
    if ($line =~ /^
	(?:Frame\:\s*(\S+))?   #frame
	\s*
	init1\:\s*(\S+)        #init1  REVERSE of fasta ordering WRONG!
	\s*
	initn\:\s*(\S+)        #initn  REVERSE of fasta ordering WRONG!
	\s*
	opt\:\s*(\S+)          #opt
	\s*
	z-score\:\s*(\S+)      #z
	\s*
	E\(\)\:\s*(\S+)        #E
	\s*
	$/xo) {

	$self->test_args($line,$2,$3,$4,$5,$6);

	(
	 $self->{'frame'},
	 $self->{'initn'},     #correct REVERSAL
	 $self->{'init1'},     #correct REVERSAL
	 $self->{'opt'},
	 $self->{'zscore'},
	 $self->{'expect'},
	) = (defined $1?$1:'',$2,$3,$4,$5,$6);
    } else {
	$self->warn("unknown field: $line");
    }
    
    $line = $text->next_line;

    if ($line =~ /^
	(?:Smith-Waterman\s+score:\s*(\d+);)?    #sw score
	\s*($RX_Ureal)%                          #percent identity
	\s*identity\s+in\s+(\d+)                 #overlap length
	\s+(?:aa|nt)\s+overlap
	\s*
	$/xo) {

	$self->test_args($line,$2,$3);
	
	(
	 $self->{'SWscore'},
	 $self->{'id_percent'},
	 $self->{'overlap'},
	) = (defined $1?$1:0,$2,$3);
    } else {
	$self->warn("unknown field: $line");
    }
    
    $self;
}


###########################################################################
package Parse::Format::FASTA2::tfastx::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT::ALN);


###########################################################################
1;
