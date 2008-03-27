# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: tfastx.pm,v 1.3 1999/09/03 20:35:58 nbrown Exp $

###########################################################################
package Parse::Format::FASTA3::tfastx;

use Parse::Format::FASTA3;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA3);


###########################################################################
package Parse::Format::FASTA3::tfastx::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA3::HEADER);


###########################################################################
package Parse::Format::FASTA3::tfastx::RANK;

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
	
	next    if $line =~ /$Parse::Format::FASTA3::RANK_START/o;

	if($line =~ /^
	   \s*
	   (\S+)                #id
	   \s+
	   (.*)                 #desc
	   \s+
	   \(\s*(\d+)\)         #aa
	   \s+
	   \[(\S)\]             #frame
	   \s+
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
	    
	    $self->test_args($line, $1,$2,$3,$4, $5,$6,$7, $8,$9);
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'     => Parse::Record::strip_leading_identifier_chars($1),
		  'desc'   => $2,
		  'length' => $3,
		  'frame'  => $4,
		  'initn'  => $5,
		  'init1'  => $6,
		  'opt'    => $7,
		  'zscore' => $8,
		  'expect' => $9,
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
package Parse::Format::FASTA3::tfastx::TRAILER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::TRAILER);


###########################################################################
package Parse::Format::FASTA3::tfastx::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT);


###########################################################################
package Parse::Format::FASTA3::tfastx::HIT::SUM;

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

    while (defined ($line = $text->next_line(1))) {
	
	if ($line =~ /^>+/) {
	    $record = $line;       #process this later
	    next;
	}

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
	    
	    $self->test_args($line,$2,$3,$4,$5,$6);
	    
	    (
	     $self->{'frame'},
	     $self->{'initn'},
	     $self->{'init1'},
	     $self->{'opt'},
	     $self->{'zscore'},
	     $self->{'expect'},
	    ) = (defined $1?'r':'f',$2,$3,$4,$5,$6);
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
	>+
	(\S+)                      #id
	\s+
	(.*)                       #description
	\s+
	\(\s*(\d+)\s*(?:aa|nt)\)   #length
	\s*
	$/xo) {

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
package Parse::Format::FASTA3::tfastx::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT::ALN);


###########################################################################
1;
