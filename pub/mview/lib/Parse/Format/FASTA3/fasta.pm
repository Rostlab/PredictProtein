# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: fasta.pm,v 1.7 1999/12/01 13:07:42 nbrown Exp $

###########################################################################
package Parse::Format::FASTA3::fasta;

use Parse::Format::FASTA3;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA3);


###########################################################################
package Parse::Format::FASTA3::fasta::HEADER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA3::HEADER);


###########################################################################
package Parse::Format::FASTA3::fasta::RANK;

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
	
	next    if $line =~ /$Parse::Format::FASTA3::RANK_START/o;

	#pre-fasta3.3 behaviour
	if ($line =~ /^
	    \s*
	    (\S+)                #id
	    \s+
	    (.*)                 #description
	    \s+
	    (?:\[[^]]+\])?       #don't know - reported by rls@ebi.ac.uk
	    \s*
	    \(\s*(\d+)\)         #aa
	    \s+
	    (?:\[(\S)\])?        #orientation
	    \s*
	    (\d+)                #initn
	    \s+
	    (\d+)                #init1
	    \s+
	    (\d+)                #opt
	    \s+
	    (\S+)                #z-score
	    \s+
	    (\S+)                #E(205044)
	    \s*
	    $/xo) {
	    
	    $self->test_args($line, $1,$2,$3, $5,$6, $7,$8,$9); #not $4
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'     => Parse::Record::strip_leading_identifier_chars($1),
		  'desc'   => $2,
		  'length' => $3,
		  'orient' => (defined $4 ? $4 : 'f'),
		  'initn'  => $5,
		  'init1'  => $6,
		  'opt'    => $7,
		  'zscore' => $8,
		  'bits'   => 0,
		  'expect' => $9,
		 });
	    next;
	}

	#fasta3.3 behaviour
	if ($line =~ /^
	    \s*
	    (\S+)                #id
	    \s+
	    (.*)                 #description
	    \s+
	    (?:\[[^]]+\])?       #don't know - reported by rls@ebi.ac.uk
	    \s*
	    \(\s*(\d+)\)         #aa
	    \s+
	    (?:\[(\S)\])?        #orientation
	    \s*
	    (\d+)                #opt
	    \s+
	    (\d+)                #bits
	    \s+
	    (\S+)                #E(205044)
	    \s*
	    $/xo) {
	    
	    $self->test_args($line, $1,$2,$3, $5,$6,$7); #not $4
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'     => Parse::Record::strip_leading_identifier_chars($1),
		  'desc'   => $2,
		  'length' => $3,
		  'orient' => (defined $4 ? $4 : 'f'),
		  'initn'  => 0,
		  'init1'  => 0,
		  'opt'    => $5,
		  'zscore' => 0,
		  'bits'   => $6,
		  'expect' => $7,
		 });
	    next;
	}
    
	#blank line or empty record: ignore
	next    if $line =~ /$Parse::Format::FASTA3::NULL/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::FASTA3::fasta::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::TRAILER);


###########################################################################
package Parse::Format::FASTA3::fasta::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT);


###########################################################################
package Parse::Format::FASTA3::fasta::HIT::SUM;

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

    while (defined ($line = $text->next_line(1))) {
	
	if ($line =~ /^>+/) {
	    $record = $line;       #process this later
	    next;
	}

	#pre-fasta3.3 behaviour
	if ($line =~ /^
	    (rev-comp)?            #frame
	    \s*
	    initn\:\s*(\S+)        #initn
	    \s*
	    init1\:\s*(\S+)        #init1
	    \s*
	    opt\:\s*(\S+)          #opt
	    \s*
            Z-score\:\s*(\S+)      #z
	    \s*
	    expect\(\)\s*(\S+)     #E
	    \s*
	    $/xo) {
	    
	    $self->test_args($line,$2,$3,$4,$5,$6); #not $1

	    (
	     $self->{'orient'},
	     $self->{'initn'},
	     $self->{'init1'},
	     $self->{'opt'},
	     $self->{'zscore'},
	     $self->{'expect'},
	    ) = (defined $1?'r':'f',$2,$3,$4,$5,$6);
	    next;
	}
	
	#fasta3.3 behaviour
	if ($line =~ /^
	    (rev-comp)?            #frame
	    \s*
	    initn\:\s*(\S+)        #initn
	    \s*
	    init1\:\s*(\S+)        #init1
	    \s*
	    opt\:\s*(\S+)          #opt
	    \s*
            Z-score\:\s*(\S+)      #z
	    \s*
	    bits\:\s*(\S+)         #bits
	    \s*
	    E\(\):\s*(\S+)         #E
	    \s*
	    /xo) {

	    $self->test_args($line,$2,$3,$4,$5,$6,$7); #not $1

	    (
	     $self->{'orient'},
	     $self->{'initn'},
	     $self->{'init1'},
	     $self->{'opt'},
	     $self->{'zscore'},
	     $self->{'bits'},
	     $self->{'expect'},
	    ) = (defined $1?'r':'f',$2,$3,$4,$5,$6,$7);
	    next;
	}
	
	if ($line =~ /^
	    (?:Smith-Waterman\s+score:\s*(\d+);)?    #sw score
	    \s*($RX_Ureal)%                          #percent identity
	    \s*identity\s+in\s+(\d+)                 #overlap length
	    \s+(?:aa|nt)\s+overlap
	    (?:\s+\((\S+)\))?                        #sequence ranges
	    /xo) {
	    
	    $self->test_args($line,$2,$3);
	    
	    (
	     $self->{'SWscore'},
	     $self->{'id_percent'},
	     $self->{'overlap'},
	     $self->{'ranges'},
	    ) = (defined $1?$1:0,$2,$3,defined $4?$4:'');
	    next;
	}
	
	#should only get here for multiline descriptions
	if (defined $self->{'initn'}) {
	    $self->warn("unknown field: $line");
	    next;
	}

	#accumulate multiline descriptions (fasta... -L)
	$record .= ' ' . $line;
    }

    #now split out the description
    if ($record =~ /^
	>*
	(\S+)                       #id
	\s+
	(.*)                        #description
	\s+
	\(\s*(\d+)\s*(?:aa|nt)\)    #length
	/xo) {
	
	$self->test_args($record, $1, $2, $3);
	
	(
	 $self->{'id'},
	 $self->{'desc'},
	 $self->{'length'},
	) = (Parse::Record::strip_leading_identifier_chars($1),
	     Parse::Record::strip_english_newlines($2), $3);
    } else {
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::FASTA3::fasta::HIT::ALN;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::FASTA::HIT::ALN);


###########################################################################
1;
