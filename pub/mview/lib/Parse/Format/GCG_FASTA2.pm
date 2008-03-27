# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: GCG_FASTA2.pm,v 1.1 1999/03/09 16:22:29 nbrown Exp $

###########################################################################
#
# Handles: GCG FASTA   2.x
#
###########################################################################
package Parse::Format::GCG_FASTA2;

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

@ISA = qw(Parse::Format::FASTA);

@VERSIONS = (
             'GCG/2' => [
			 'FASTA',
			],
            );

$NULL  = '^\s*$';#for emacs'

$ENTRY_START   = '^\(\S+\)\s+FASTA of:';
$ENTRY_END     = '! Output File:';

$HEADER_START  = $ENTRY_START;
$HEADER_END    = '^The best scores are:'; 
               
$RANK_START    = $HEADER_END;
$RANK_END      = $Parse::Format::FASTA::GCG_JUNK;
               
$TRAILER_START = '^! CPU time used:';
$TRAILER_END   = $ENTRY_END;

$HIT_START     = '^\S+(?:\s+/rev)?\s*$';
$HIT_END       = "(?:$HIT_START|$TRAILER_START|$ENTRY_END)";

$SUM_START     = $HIT_START;
$SUM_END       = '% identity in';
       
$ALN_START     = '^\s+\d+\s+';    #the ruler
$ALN_END       = '(?:^\S+(?:\s+/rev)?\s*$' . "|$HIT_END)";#for emacs'


###########################################################################
#Parse one entry: generic for all FASTA family
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
	    $text->scan_until_inclusive($RANK_END, 'RANK');
	    next;			       	      
	}				       	      

	#Hit lines		       	      
	if ($line =~ /$HIT_START/o) {
	    $text->scan_skipping_until($HIT_END, 1, 'HIT');
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
package Parse::Format::GCG_FASTA2::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HEADER);

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

    my ($ac, $id) = (undef, undef);

    while (defined ($line = $text->next_line)) {

        #GCG fasta doesn't write explicit versioning

        #GCG filename and from/to giving query length
        if ($line =~ /^\s*
            \(\S+\)
            \s+
            FASTA of:\s+(\S+)    #file
            \s+
            from:\s+(\d+)        #from position
            \s+
            to:\s+(\d+)          #to position
            /xo) {

            $self->test_args($line, $1, $2);
            (
             $self->{'queryfile'},
             $self->{'length'},
            ) = ($1, ($3 > $2 ? $3-$2+1 : $2-$3+1));
            next;
        }

        #query identifier
        if ($line =~ /^\s*ID\s{3}(\S+);?/) {
            $self->test_args($line, $1);
            $id = $1;
            next;
        }

        #query accession
        if ($line =~ /^\s*AC\s{3}(\S+);?/) {
            $self->test_args($line, $1);
            $ac = $1;
            next;
        }

        #database size
        if ($line =~ /.*
            Sequences:\s+(\S+)       #sequence count (contains commas)
            \s+
            Symbols:\s+(\S+)         #symbol count (contains commas)
            /xo) {

            $self->test_args($line, $1,$2);

            (
             $self->{'sequences'},
             $self->{'residues'},
            ) = ($1, $2);

            $self->{'sequences'} =~ s/,//g;
            $self->{'residues'}  =~ s/,//g;

            next;
        }

        #ignore any other text

    }

    if (! defined $self->{'full_version'} ) {
        #can't determine version: hardwire one!
        $self->{'full_version'} = 'GCG FASTA 2';
        $self->{'version'}      = '2';
    }

    if (defined $id and defined $ac) {
        $self->{'query'} = "$ac:$id";
    } elsif (defined $id) {
        $self->{'query'} = "$id";
    } elsif (defined $ac) {
        $self->{'query'} = "$ac";
    } elsif (defined $self->{'queryfile'}) {
        $self->{'query'} = $self->{'queryfile'};
    } else {
        $self->{'query'} = 'query';
    }

    $self;
}


###########################################################################
package Parse::Format::GCG_FASTA2::RANK;

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

    my ($id, $desc, $init1, $initn, $opt, $z, $e);

    $self->{'hit'} = [];

    #ranked search hits
    while (defined ($line = $text->next_line)) {

        next    if $line =~ /$Parse::Format::GCG_FASTA2::RANK_START/o;
        next    if $line =~ /$Parse::Format::FASTA::GCG_JUNK/o;

	#first line
        if ($line =~ /^\s*
           ([^\s]+)                #id
           \s+
           Begin:\s+(\d+)          #start position
           \s+
           End:\s+(\d+)            #end position
	   /xo) {

	    #initialise
            ($id,$desc,$init1,$initn,$opt,$z,$e) = ('','','','','','','');

	    #warn "($1,$2,$3)\n";

	    $self->test_args($line, $1);
	    
	    $id = Parse::Record::strip_leading_identifier_chars($1);

	    #read next line
	    $line = $text->next_line;

	    #second line
	    if ($line =~ /
		\s+
		(\d+)                   #init1
		\s+
		(\d+)                   #initn
		\s+
		(\d+)                   #opt
		\s+
		(\S+)                   #z-score
		\s+
		(\S+)                   #E(58765)
		\s*$
		$/xo) {
		
		#warn "($1,$2,$3,$4,$5)\n";

		$self->test_args($line, $1,$2,$3,$4,$5);
	    
		($init1,$initn,$opt,$z,$e) = ($1,$2,$3,$4,$5);

		$desc = $`;

		$desc =~ s/^\s*!\s*//;
	    }

	    push(@{$self->{'hit'}},
		 {
		  'id'     => $id,
		  'desc'   => $desc,
		  'initn'  => $initn,
		  'init1'  => $init1,
		  'opt'    => $opt,
		  'zscore' => $z,
		  'expect' => $e,
		 });
	    
	    next;
        }
	
        #blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::GCG_FASTA2::NULL/o;

        #default
        $self->warn("unknown field: $line");
    }

    $self;
}


###########################################################################
package Parse::Format::GCG_FASTA2::TRAILER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::TRAILER);


###########################################################################
package Parse::Format::GCG_FASTA2::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT);

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

	#identifier lines
	if ($line =~ /$Parse::Format::GCG_FASTA2::SUM_START/o) {
	    $text->scan_until_inclusive($Parse::Format::GCG_FASTA2::SUM_END, 'SUM');
	    next;
	}

	#fragment hits: terminated by several possibilities
	if ($line =~ /$Parse::Format::GCG_FASTA2::ALN_START/o) {
	    $text->scan_until($Parse::Format::GCG_FASTA2::ALN_END, 'ALN');
	    next;
	}
	
	#blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::GCG_FASTA2::NULL/o;

	#ugly: skip queryfile or hit identifier lines
	next    if $line =~ /$Parse::Format::GCG_FASTA2::ALN_END/;

	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Parse::Format::GCG_FASTA2::HIT::SUM;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::FASTA::HIT);

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

    my ($id1, $id2, $ac, $de) = ('','','','');

    #skip first line (query filename)
    $text->next_line;

    while (defined ($line = $text->next_line)) {

	#hit database:identifier: appears as line 2
	if ($line =~ /^\s*(\S+:\S+);?\s*$/) {
	    $id1 = $1;
	    next;
	}

	#hit identifier
	if ($line =~ /^ID\s{3}(\S+);?.*;\s+(\d+)\s+\S+\./o) {
	    $id2 = $1;
	    $self->{'length'} = $2;
	    next;
	}

	#hit accession
	if ($line =~ /^AC\s{3}(\S+);?/o) {
	    $ac = $1;
	    next;
	}

	#hit description
	if ($line =~ /^DE\s{3}(.*)/o) {
            $de .= Parse::Record::strip_english_newlines($1);
	    $de =~ s/\s*\.\s\.\s\.\s*$//;
	    $de =~ s/\s*\.\.\.\*$//;
	    next;
	}

	#skip other database entry lines
	next    if $line =~ /^(NI|DT|DE)\s{3}/o;

	#blank line or empty record: ignore
        next    if $line =~ /$Parse::Format::GCG_FASTA2::NULL/o;
	
	#scores
	if ($line =~ /^
	    SCORES\s+
	    init1\:\s*(\S+)        #init1
	    \s*
	    initn\:\s*(\S+)        #initn
	    \s*
	    opt\:\s*(\S+)          #opt
	    \s*
	    z-score\:\s*(\S+)      #z
	    \s*
	    E\(\)\:\s*(\S+)        #E
	    \s*
	    $/ixo) {
	    
	    $self->test_args($line,$1,$2,$3,$4,$5);
	    
	    (
	     $self->{'init1'},
	     $self->{'initn'},
	     $self->{'opt'},
	     $self->{'zscore'},
	     $self->{'expect'},
	    ) = ($1,$2,$3,$4,$5);

	    $self->{'id'}   = ($id1 ne '' ? $id1 : $id2);
	    $self->{'desc'} = $de;

	    next;
	}
	
	if ($line =~ /^
	    #smith-waterman in fasta2 and fasta3, maybe in gcg?
	    (?:Smith-Waterman\s+score:\s*(\d+);)?    #sw score
	    \s*($RX_Ureal)%                          #percent identity
	    \s*identity\s+in\s+(\d+)                 #overlap length
	    \s+(?:aa|nt|bp)\s+overlap
	    \s*$/xo) {

	    $self->test_args($line,$2,$3);
	    
	    (
	     $self->{'SWscore'},
	     $self->{'id_percent'},
	     $self->{'overlap'},
	    ) = (defined $1?$1:0,$2,$3);

	    next;
	}
	
	#default
	$self->warn("unknown field: $line");
    }

    $self;
}


###########################################################################
package Parse::Format::GCG_FASTA2::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Format::FASTA::HIT::ALN);


###########################################################################
1;
