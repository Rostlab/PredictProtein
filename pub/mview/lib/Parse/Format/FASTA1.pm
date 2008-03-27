# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA1.pm,v 1.3 1999/09/03 20:35:54 nbrown Exp $

###########################################################################
#
# Handles: FASTA  1.x
#
###########################################################################
package Parse::Format::FASTA1;

use Parse::Format::FASTA;
use strict;

use vars qw(@ISA

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
	     '1' => [
		     'FASTA',
		    ],
	    );

$NULL  = '^\s*$';#for emacs';

$ENTRY_START   = '(?:'
    . '^\s*fasta.*searches a sequence data bank'
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

$HIT_START     = '^\S{7}.*\d+\s+\d+\s+\d+\s*$';#for emacs';
$HIT_END       = "(?:$HIT_START|$ENTRY_END)";

$SUM_START     = $HIT_START;
$SUM_END       = $NULL;
       
$ALN_START     = '^\s+\d+\s+';    #the ruler
$ALN_END       = $HIT_END;

sub new { my $self=shift; $self->SUPER::new(@_) }


###########################################################################
1;
