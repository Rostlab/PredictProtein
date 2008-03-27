# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: BLAST1.pm,v 1.2 1999/02/19 16:55:47 nbrown Exp $

###########################################################################
#
# Base classes for NCBI BLAST1, WashU BLAST2 families.
#
# Handles: BLAST 1.4.x, WashU 2.0x
#
# BLAST (pre NCBI version 2) parsing consists of 6 main record types:
#
#   HEADER        the header text
#   WARNING       optional warning messages
#   HISTOGRAM     the optional scores histogram
#   RANK          the list of ordered high scoring hits
#   HIT           the set of fragments (HSPs) for a given hit
#   PARAMETERS    the trailer
#
# HIT is further subdivided into:
#   SUM           the summary lines for each hit
#   ALN           each aligned fragment: score + alignment
#
###########################################################################
package Parse::Format::BLAST1;

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

            $HISTOGRAM_START
            $HISTOGRAM_END

            $HEADER_START
            $HEADER_END

            $SCORE_START
            $SCORE_END
	   );

@ISA   = qw(Parse::Format::BLAST);

@VERSIONS = ( 
	     '1' => [
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
$ENTRY_END        = '^WARNINGS\s+ISSUED:';

$WARNING_START	  = '^WARNING:';
$WARNING_END	  = $NULL;

$WARNINGS_START	  = '^WARNINGS\s+ISSUED:';
$WARNINGS_END	  = $NULL;

$PARAMETERS_START = '^Parameters';
$PARAMETERS_END	  = "(?:$WARNINGS_START|$ENTRY_START)";

#$HIT_START	  = '(?:^>|^[^\|:\s]+\|)';  #fails for some long query text
$HIT_START	  = '^>';                   #fails for web pages
$HIT_END	  = "(?:$HIT_START|$WARNING_START|$PARAMETERS_START|$PARAMETERS_END)";

$RANK_START	  = '^\s+Smallest';
$RANK_MATCH	  = "(?:$NULL|^\\s+Smallest|^\\s+Sum|^\\s+High|^\\s+Reading|^\\s*Sequences|^[^>].*$RX_Uint\\s+$RX_Ureal\\s+$RX_Uint|$Parse::Format::BLAST::GCG_JUNK)";
$RANK_END	  = $HIT_END;

$HISTOGRAM_START  = '^\s+Observed Numbers';
$HISTOGRAM_END	  = "(?:$RANK_START|$RANK_END)";

$HEADER_START     = $ENTRY_START;
$HEADER_END       = "(?:$WARNING_START|$HISTOGRAM_START|$HISTOGRAM_END)";

$SCORE_START      = '^ Score';
$SCORE_END        = "(?:$SCORE_START|$HIT_START|$PARAMETERS_START)";


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

	#Histogram lines
	if ($line =~ /$HISTOGRAM_START/o) {
	    $text->scan_until($HISTOGRAM_END, 'HISTOGRAM');
	    next;
	}

	#Rank lines: override $RANK_END definition
	if ($line =~ /$RANK_START/o) {       	      
	    $text->scan_while($RANK_MATCH, 'RANK');
	    next;
	}				       	      
	
	#Hit lines
	if ($line =~ /$HIT_START/o) {
	    $text->scan_until($HIT_END, 'HIT');
	    next;			       	      
	}				       	      
	
	#WARNING lines
	if ($line =~ /$WARNING_START/o) {       	      
	    $text->scan_until($WARNING_END, 'WARNING');
	    next;			       	      
	}				       	      

	#Parameter lines
	if ($line =~ /$PARAMETERS_START/o) {       	      
	    $text->scan_until($PARAMETERS_END, 'PARAMETERS');
	    next;			       	      
	}				       	      
	
	#WARNINGS ISSUED line: ignore
	next    if $line =~ /$WARNINGS_START/o;

	#blank line or empty record: ignore
	next    if $line =~ /$NULL/o;

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}


###########################################################################
1;
