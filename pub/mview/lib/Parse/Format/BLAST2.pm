# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: BLAST2.pm,v 1.4 1999/09/13 17:15:17 nbrown Exp $

###########################################################################
#
# Base classes for NCBI BLAST2 family.
#
# Handles: BLAST 2.0.x
#
# BLAST (NCBI version 2) iterated searching uses 3 main record types:
#
#   HEADER        the header text
#   SEARCH        passes of the search engine
#   PARAMETERS    the trailer
#
#   SEARCH is further subdivied into:
#     RANK        the list of ordered high scoring hits
#     HIT         the set of alignments for a given hit
#
#   HIT is further subdivided into:
#     SUM         the summary lines for each hit
#     HIT         each aligned fragment: score + alignment
#
###########################################################################
package Parse::Format::BLAST2;

use Parse::Format::BLAST;
use Regexps;

use strict;

use vars qw(@ISA

	    @VERSIONS

	    $NULL

	    $ENTRY_START
	    $ENTRY_END

            $WARNING_START
            $WARNING_END

            $WARNINGS_START
            $WARNINGS_END

            $PARAMETERS_START
            $PARAMETERS_END

            $HIT_START
            $HIT_END

            $RANK_START
            $RANK_MATCH
            $RANK_END
            $RANK_NONE

            $HEADER_START
            $HEADER_END

            $SEARCH_START
            $SEARCH_END

            $SCORE_START
            $SCORE_END
	   );

@ISA   = qw(Parse::Format::BLAST);

@VERSIONS = ( 
	     '2' => [
		     'BLASTP',
		     'BLASTN',
		     'BLASTX',
		     'TBLASTN',
		     'TBLASTX',
		    ],
	    );

$NULL  = '^\s*$';#for emacs';

$ENTRY_START      = '(?:'
    . '^BLASTP'
    . '|'
    . '^BLASTN'
    . '|'
    . '^BLASTX'
    . '|'
    . '^TBLASTN'
    . '|'
    . '^TBLASTX'
    . ')';
$ENTRY_END        = '^  WARNINGS\s+ISSUED:';    #blast1 behavior, but blast2?

$SEARCH_START     = '^Searching';
$SEARCH_END       = "(?:$SEARCH_START|  Database)";

$WARNING_START    = '^WARNING';
$WARNING_END      = $NULL;

$WARNINGS_START   = '^WARNINGS\s+ISSUED:';
$WARNINGS_END     = $NULL;

$PARAMETERS_START = '^  Database';
$PARAMETERS_END   = "(?:$WARNINGS_START|$ENTRY_START)";

#$HIT_START	  = '(?:^>|^[^\|:\s]+\|)';  #fails for some long query text
$HIT_START	  = '^>';                   #fails for web pages
$HIT_END          = "(?:$HIT_START|$WARNING_START|$SEARCH_END)";

$RANK_START       = $SEARCH_START;
$RANK_MATCH	  = "(?:$NULL|^\\s+High|^\\s+Score|^\\s*Sequences|^\\s*CONVERGED|No hits found|^[^>].*$RX_Uint\\s+$RX_Ureal|$Parse::Format::BLAST::GCG_JUNK)";
$RANK_END         = "(?:$HIT_START|$SEARCH_END)"; #ignore warnings
$RANK_NONE        = '^\s*\*\*\* NONE';

$HEADER_START     = $ENTRY_START;
$HEADER_END       = "(?:$SEARCH_START|$WARNING_START|$RANK_START|$HIT_START|$PARAMETERS_START)";

$SCORE_START      = '^\s*Score';
$SCORE_END        = "(?:$SCORE_START|$HIT_END)";


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

	#blank line or empty record: ignore
	next    if $line =~ /$NULL/o;

	#Header lines
	if ($line =~ /$HEADER_START/o) {
	    $text->scan_until($HEADER_END, 'HEADER');
	    next;
	}

	#Search lines
	if ($line =~ /$SEARCH_START/o) {
	    $text->scan_until($SEARCH_END, 'SEARCH');
	    next;
	}

	#Parameter lines
	if ($line =~ /$PARAMETERS_START/o) {       	      
	    $text->scan_until($PARAMETERS_END, 'PARAMETERS');
	    next;			       	      
	}				       	      
	
	#WARNINGS ISSUED line: ignore
	next    if $line =~ /$WARNINGS_START/o;

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}

#BLAST2 or PSI-BLAST write  'e10' instead of '1e10', so fix this.
sub fix_expect {
    my $e = shift;
    $e =~ s/^e/1e/;
    $e;
}


###########################################################################
package Parse::Format::BLAST2::SEARCH;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

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

    while (defined ($line = $text->next_line)) {

	#Rank lines
	if ($line =~ /$Parse::Format::BLAST2::RANK_START/o) {       	      
#	    $text->scan_while($Parse::Format::BLAST2::RANK_MATCH, 'RANK');
	    #this simpler boundary test seems to work ok with BLAST2; the
	    #older scan_while() must have been for earlier BLAST versions.
 	    $text->scan_until($Parse::Format::BLAST2::RANK_END, 'RANK');
	    next;			       	      
	}				       	      
	
	#Hit lines
	if ($line =~ /$Parse::Format::BLAST2::HIT_START/o) {       	      
	    $text->scan_until($Parse::Format::BLAST2::HIT_END, 'HIT');
	    next;			       	      
	}				       	      
	
	#WARNING lines
	if ($line =~ /$Parse::Format::BLAST2::WARNING_START/o) {       	      
	    $text->scan_until($Parse::Format::BLAST2::WARNING_END, 'WARNING');
	    next;			       	      
	}				       	      
	
	#blank line or empty record: ignore
	next    if $line =~ /$Parse::Format::BLAST2::NULL/o;

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}


###########################################################################
package Parse::Format::BLAST2::SEARCH::RANK;

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
    #$self->{'header'} = $text->scan_lines(4);    #<= 2.0.5
    #$self->{'header'} = $text->scan_lines(6);    #2.0.6
    $self->{'header'} = $text->scan_until_inclusive('Value(?:\s*N)?\s*$');#'

    #ranked search hits 
    $self->{'hit'}    = [];
    
    while (defined ($line = $text->next_line)) {
	
	next    if $line =~ /^Sequences used in model and found again:/;
	next    if $line =~ /^Sequences not found previously or not previously below threshold:/;
	next    if $line =~ /^CONVERGED!/;
	next    if $line =~ /^Significant /;    #PHI-BLAST

	#blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::BLAST2::NULL/o;

	#GCG annotation: ignore
        next    if $line =~ /$Parse::Format::BLAST::GCG_JUNK/o;

	#empty ranking: done
        last    if $line =~ /$Parse::Format::BLAST2::RANK_NONE/o;

	chomp $line;

	my $tmp = {};

	#examine suffix
	if ($line =~ /
            \s+
	    ($RX_Ureal)                #bits
	    \s+
	    ($RX_Ureal)                #E value
            (?:\s+($RX_Uint))?         #N (ungapped blast only)
	    \s*$
	    /xo) {

	    $self->test_args($line, $1, $2);
	    
	    $tmp->{'bits'}   = $1;
	    $tmp->{'expect'} = Parse::Format::BLAST2::fix_expect($2);
	    $tmp->{'n'}      = (defined $3 ? $3 : 0);

	    #examine prefix
	    if ($` =~ /^\s*
		(\S+)                  #id
		\s*
		\!?                    #GCG junk
		\s*
		(.*)?                  #summary
		/xo) {
		    
		$self->test_args($line, $1);    #ignore $2
		
		$tmp->{'id'} = 
		    Parse::Record::strip_leading_identifier_chars($1);
		$tmp->{'summary'} =
		    Parse::Record::strip_trailing_space($2);
		
	    } else {
		$self->warn("unknown field: $line");
	    }
	    
	    push @{$self->{'hit'}}, $tmp;
	    
	    next;
	}
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::BLAST2::SEARCH::HIT::ALN;

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
	($RX_Ureal)                 #bits
	\s+bits\s+
	\(($RX_Ureal)\),            #score
	\s+
	Expect(?:\((\d+)\))?\s*=\s*
	($RX_Ureal)                 #expectation
	/xo) {
	
	$self->test_args($line, $1, $2, $4);

	(
	 $self->{'bits'},
	 $self->{'score'},
	 $self->{'n'},              #substitute 1 unless $3
	 $self->{'expect'},
	) = ($1, $2, defined $3?$3:1, Parse::Format::BLAST2::fix_expect($4));

    } else {
	$self->warn("expecting 'Score' line: $line");
    }
    
    #Identities line
    $line = $text->next_line;

    if ($line =~ /^\s*
	Identities\s*=\s*
	(\d+\/\d+)                  #identities fraction
	\s+			    
	\((\d+)%\)                  #identities percentage
	(?:                         #not present in (some?) BLASTN 2.0.9
	,\s+			    
	Positives\s*=\s*	    
	(\d+\/\d+)                  #positives fraction
	\s+			    
	\((\d+)%\)                  #positives percentage
	(?:,\s*			    #not always present
	 Gaps\s*=\s*		    
	 (\d+\/\d+)                 #gaps fraction
	 \s+			    
	 \((\d+)%\)                 #gaps percentage
	)?
	)?
	/xo) {
	
	$self->test_args($line, $1, $2);

	(
	 $self->{'id_fraction'},
	 $self->{'id_percent'},
	 $self->{'pos_fraction'},
	 $self->{'pos_percent'},
	 $self->{'gap_fraction'},
	 $self->{'gap_percent'},
	) = ($1, $2, defined $3?$3:'', defined $4?$4:0, defined $5?$5:'', defined $6?$6:0);
	
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
    printf "$x%20s -> %s\n",   'bits',           $self->{'bits'};
    printf "$x%20s -> %s\n",   'score',          $self->{'score'};
    printf "$x%20s -> %s\n",   'n',              $self->{'n'};
    printf "$x%20s -> %s\n",   'expect',         $self->{'expect'};
    printf "$x%20s -> %s\n",   'id_fraction',    $self->{'id_fraction'};
    printf "$x%20s -> %s\n",   'id_percent',     $self->{'id_percent'};
    printf "$x%20s -> %s\n",   'pos_fraction',   $self->{'pos_fraction'};
    printf "$x%20s -> %s\n",   'pos_percent',    $self->{'pos_percent'};
    printf "$x%20s -> %s\n",   'gap_fraction',   $self->{'gap_fraction'};
    printf "$x%20s -> %s\n",   'gap_percent',    $self->{'gap_percent'};
    $self->SUPER::print($indent);
}


###########################################################################
1;
