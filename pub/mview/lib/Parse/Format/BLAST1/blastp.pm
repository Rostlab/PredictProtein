# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: blastp.pm,v 1.2 1999/02/19 16:55:51 nbrown Exp $

###########################################################################
package Parse::Format::BLAST1::blastp;

use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST1);

my $RANK_NONE    = '^\s*\*\*\* NONE';
my $RANK_CUT     = 60;


###########################################################################
package Parse::Format::BLAST1::blastp::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HEADER);


###########################################################################
package Parse::Format::BLAST1::blastp::RANK;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::BLAST::RANK);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    #column headers
    $self->{'header'} = $text->scan_lines(4);

    #ranked search hits
    $self->{'hit'}    = [];

    while (defined ($line = $text->next_line)) {
	
	#blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::BLAST1::NULL/o;

	#GCG annotation: ignore
        next    if $line =~ /$Parse::Format::BLAST::GCG_JUNK/o;

	#empty ranking: done
        last    if $line =~ /$RANK_NONE/o;

	chomp $line;

	#excise variable length description and append it
	my $tmp = substr($line, 0, $RANK_CUT);
	if ($tmp =~ /^\s*([^\s]+)(.*)/) {
	    $line = $1 . substr($line, $RANK_CUT). $2;
	}

	if ($line =~ /\s*
	    ([^\s]+)                          #id
	    \s+
	    ($RX_Uint)                        #score
	    \s+
	    ($RX_Ureal)                       #p-value
	    \s+
	    ($RX_Uint)                        #n fragments
	    \s*
	    \!?                               #GCG junk
	    \s*
	    (.*)                              #summary
	    /xo) {

	    $self->test_args($line, $1, $2, $3, $4); #ignore $5
	    
	    push @{$self->{'hit'}}, 
	    {
	     'id'      => Parse::Record::strip_leading_identifier_chars($1),
	     'score'   => $2,
	     'p'       => $3,
	     'n'       => $4,
	     'summary' => Parse::Record::strip_trailing_space($5),
	    };

	    next;
	}
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::BLAST1::blastp::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT);


###########################################################################
package Parse::Format::BLAST1::blastp::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT::SUM);


###########################################################################
package Parse::Format::BLAST1::blastp::HIT::ALN;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::BLAST::HIT::ALN);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self);

    #Score line
    $line = $text->next_line;

    if ($line =~ /^\s*
	Score\s*=\s*
	($RX_Uint)                           #score
	\s+
	\(($RX_Ureal)\s+bits\),              #bits
	\s+
	Expect\s*=\s*
	($RX_Ureal),                         #expectation
	\s+
	(?:Sum\sP\((\d+)\)|P)\s*=\s*         #number of frags
	($RX_Ureal)                          #p-value
	/xo) {
	
	$self->test_args($line, $1, $2, $3, $5);

	(
	 $self->{'score'},
	 $self->{'bits'},
	 $self->{'expect'},
	 $self->{'n'},                       #substitute 1 unless $4
	 $self->{'p'},
	) = ($1, $2, $3, defined $4?$4:1, $5);
    }
    else {
	$self->warn("expecting 'Score' line: $line");
    }
    
    #Identities line
    $line = $text->next_line;

    if ($line =~ /^\s*
	Identities\s*=\s*
	(\d+\/\d+)                           #identities fraction
	\s+
	\((\d+)%\),                          #identities percentage
	\s+
	Positives\s*=\s*
	(\d+\/\d+)                           #positives fraction
	\s+
	\((\d+)%\)                           #positives percentage
	/xo) {
	
	$self->test_args($line, $1, $2, $3, $4);

	(
	 $self->{'id_fraction'},
	 $self->{'id_percent'},
	 $self->{'pos_fraction'},
	 $self->{'pos_percent'},
	) = ($1, $2, $3, $4);

	#record query orientation in HIT list (always +)
	push @{$parent->{'orient'}->{'+'}}, $self;
	
    } else {
	$self->warn("expecting 'Identities' line: $line");
    }

    $self->parse_alignment($text);

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'score',          $self->{'score'};
    printf "$x%20s -> %s\n",   'bits',           $self->{'bits'};
    printf "$x%20s -> %s\n",   'expect',         $self->{'expect'};
    printf "$x%20s -> %s\n",   'p',              $self->{'p'};
    printf "$x%20s -> %s\n",   'n',              $self->{'n'};
    printf "$x%20s -> %s\n",   'id_fraction',    $self->{'id_fraction'};
    printf "$x%20s -> %s\n",   'id_percent',     $self->{'id_percent'};
    printf "$x%20s -> %s\n",   'pos_fraction',   $self->{'pos_fraction'};
    printf "$x%20s -> %s\n",   'pos_percent',    $self->{'pos_percent'};
    $self->SUPER::print($indent);
}


###########################################################################
package Parse::Format::BLAST1::blastp::WARNING;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::WARNING);


###########################################################################
package Parse::Format::BLAST1::blastp::HISTOGRAM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HISTOGRAM);


###########################################################################
package Parse::Format::BLAST1::blastp::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
