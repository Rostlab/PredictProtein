# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA.pm,v 1.3 1999/09/03 20:35:53 nbrown Exp $

###########################################################################
#
# Base classes for FASTA family.
#
# FASTA parsing consists of 4 main record types:
#
#   HEADER        the header text (not much interesting)
#   RANK          the list of ordered hits and initn/init1/opt (scores)
#   HIT           each hit's alignment with the query
#   TRAILER       trailing run-time data
#
# HIT is further subdivided into:
#   SUM          the summary lines for each hit: name, description, scores
#   ALN          the aligned fragments
#
#
# Acknowledgements.
#
# Christophe Leroy, 22/8/97 for original fasta1 version.
#
###########################################################################
package Parse::Format::FASTA;

use vars qw(@ISA $GCG_JUNK);
use strict;

@ISA = qw(Parse::Record);

BEGIN { $GCG_JUNK = '(?:^\.\.|^\\\\)' }

use Parse::Format::FASTA1;
use Parse::Format::FASTA2;
use Parse::Format::FASTA3;
use Parse::Format::GCG_FASTA2;

my %VERSIONS = (
		@Parse::Format::FASTA1::VERSIONS,
		@Parse::Format::FASTA2::VERSIONS,
		@Parse::Format::FASTA3::VERSIONS,
                @Parse::Format::GCG_FASTA2::VERSIONS,
	       );

my $NULL        = '^\s*$';#for emacs';
    
my $ENTRY_START = "(?:"
    . $Parse::Format::FASTA1::ENTRY_START
    . "|"
    . $Parse::Format::FASTA2::ENTRY_START
    . "|"
    . $Parse::Format::FASTA3::ENTRY_START
    . "|"
    . $Parse::Format::GCG_FASTA2::ENTRY_START
    . ")";
my $ENTRY_END = "(?:"
    . $Parse::Format::FASTA1::ENTRY_END
    . "|"
    . $Parse::Format::FASTA2::ENTRY_END
    . "|"
    . $Parse::Format::FASTA3::ENTRY_END
    . "|"
    . $Parse::Format::GCG_FASTA2::ENTRY_END
    . ")";

my $HEADER_START = "(?:"
    . $Parse::Format::FASTA1::HEADER_START
    . "|"		      
    . $Parse::Format::FASTA2::HEADER_START
    . "|"		      
    . $Parse::Format::FASTA3::HEADER_START
    . "|"		      
    . $Parse::Format::GCG_FASTA2::HEADER_START
    . ")";		      
my $HEADER_END = "(?:"    
    . $Parse::Format::FASTA1::HEADER_END
    . "|"		      
    . $Parse::Format::FASTA2::HEADER_END
    . "|"		      
    . $Parse::Format::FASTA3::HEADER_END
    . "|"		      
    . $Parse::Format::GCG_FASTA2::HEADER_END
    . ")";

my $RANK_START = "(?:"
    . $Parse::Format::FASTA1::RANK_START
    . "|"		      
    . $Parse::Format::FASTA2::RANK_START
    . "|"		      
    . $Parse::Format::FASTA3::RANK_START
    . "|"		      
    . $Parse::Format::GCG_FASTA2::RANK_START
    . ")";		      
my $RANK_END = "(?:"   
    . $Parse::Format::FASTA1::RANK_END
    . "|"		      
    . $Parse::Format::FASTA2::RANK_END
    . "|"		      
    . $Parse::Format::FASTA3::RANK_END
    . "|"		      
    . $Parse::Format::GCG_FASTA2::RANK_END
    . ")";

my $HIT_START = "(?:"
    . $Parse::Format::FASTA1::HIT_START
    . "|"		      
    . $Parse::Format::FASTA2::HIT_START
    . "|"		      
    . $Parse::Format::FASTA3::HIT_START
    . "|"		      
    . $Parse::Format::GCG_FASTA2::HIT_START
    . ")";
my $HIT_END = "(?:"
    . $Parse::Format::FASTA1::HIT_END
    . "|"		      
    . $Parse::Format::FASTA2::HIT_END
    . "|"		      
    . $Parse::Format::FASTA3::HIT_END
    . "|"		      
    . $Parse::Format::GCG_FASTA2::HIT_END
    . ")";

my $SUM_START = "(?:"
    . $Parse::Format::FASTA1::SUM_START
    . "|"			      
    . $Parse::Format::FASTA2::SUM_START
    . "|"			      
    . $Parse::Format::FASTA3::SUM_START
    . "|"			      
    . $Parse::Format::GCG_FASTA2::SUM_START
    . ")";
my $SUM_END = "(?:"
    . $Parse::Format::FASTA1::SUM_END
    . "|"			      
    . $Parse::Format::FASTA2::SUM_END
    . "|"			      
    . $Parse::Format::FASTA3::SUM_END
    . "|"			      
    . $Parse::Format::GCG_FASTA2::SUM_END
    . ")";

my $ALN_START = "(?:"
    . $Parse::Format::FASTA1::ALN_START
    . "|"			      
    . $Parse::Format::FASTA2::ALN_START
    . "|"			      
    . $Parse::Format::FASTA3::ALN_START
    . "|"			      
    . $Parse::Format::GCG_FASTA2::ALN_START
    . ")";
my $ALN_END = "(?:"
    . $Parse::Format::FASTA1::ALN_END
    . "|"			      
    . $Parse::Format::FASTA2::ALN_END
    . "|"			      
    . $Parse::Format::FASTA3::ALN_END
    . "|"			      
    . $Parse::Format::GCG_FASTA2::ALN_END
    . ")";

my $TRAILER_START = "(?:"
    . $Parse::Format::FASTA1::TRAILER_START
    . "|"
    . $Parse::Format::FASTA2::TRAILER_START
    . "|"
    . $Parse::Format::FASTA3::TRAILER_START
    . "|"
    . $Parse::Format::GCG_FASTA2::TRAILER_START
    . ")";
my $TRAILER_END = "(?:"   
    . $Parse::Format::FASTA1::TRAILER_END
    . "|"
    . $Parse::Format::FASTA2::TRAILER_END
    . "|"
    . $Parse::Format::FASTA3::TRAILER_END
    . "|"
    . $Parse::Format::GCG_FASTA2::TRAILER_END
    . ")";


#Generic get_entry() and new() constructors for all FASTA style parsers:
#determine program and version and coerce appropriate subclass.

#Consume one entry-worth of input on stream $fh associated with $file and
#return a new FASTA instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);
    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};
    my ($type, $prog, $version, $class, $format) = ('Parse::Format::FASTA');
    my ($GCG, $self) = (0);

    while (defined ($line = <$fh>)) {

	#start of entry
	if ($line =~ /$ENTRY_START/o and $offset < 0) { 
	    $offset = $fh->tell - length($line);
	    #fall through for version tests
	}

	#end of entry
	last    if $line =~ /$ENTRY_END/o;

	#escape iteration if we've hit the alignment section
	next    if $line =~ /$ALN_START/;

	#try to get program and version from header; these headers are
	#only present if stderr was collected. sigh.

	#try to determine program
	if ($line =~ /^\s*(\S+)\s+(?:searches|compares|translates)/) {
	    #FASTA family versions 2 upwards
	    $prog = $1;
	    next;
	} elsif ($line =~ /^\s*(\S+)\s+(?:searches|compares)/) {
	    #FASTA version 1
	    $prog = $1;
	    next;
	}
	
	#try to determine version from header
	if ($line =~ /^\s*version\s+(\d+)/) {
	    $version = $1;
	} elsif ($line =~ /^\s*v(\d+)\.\d+\S\d+/) {
	    $version = $1;
	}
	
	#otherwise... stderr header was missing... look at stdout part

	#try to determine FASTA version by minor differences
	if ($line =~ /The best scores are:\s+initn\s+init1\s+opt\s*$/) {
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 1          unless defined $version;
	    next;
	}

	if ($line =~ /The best scores are:\s+initn\s+init1\s+opt\s+z-sc/) {
	    #matches FASTA2,FASTA3,TFASTX3, but next rules commit first
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 2          unless defined $version;
	    next;
	}

	if ($line =~ /The best scores are:\s+init1\s+initn\s+opt\s+z-sc/) {
	    #matches GCG FASTA2
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 2          unless defined $version;
	    $GCG = 1;
	    next;
	}

	if ($line =~ /^(\S+)\s+\((\d+)/) {
	    $prog    = $1          unless defined $prog;
	    $version = $2          unless defined $version;
	    next;
	}

	if ($line =~ /frame-shift:/) {
	    $prog    = 'TFASTX';    #guess
	    next;
	}
	if ($line =~ /$GCG_JUNK/) {
	    #matches GCG
	    $GCG = 1;
	    next;
	}

    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    #ugly: TFASTX version 3.1t0.7 renamed itself to TFASTXY
    $prog = 'TFASTX'    if $prog eq 'TFASTXY';

    unless (defined $prog and defined $version) {
	die "get_entry() top-level FASTA parser could not determine program/version\n";
    }

    unless (exists $VERSIONS{$version} and 
	    grep(/^$prog$/i, @{$VERSIONS{$version}}) > 0) {
	die "get_entry() parser for program '$prog' version '$version' not implemented\n";
    }

    $prog = lc $prog;
    $format = uc $prog;
    $version =~ s/-/_/g;
    if ($GCG) {
	$class = "Parse::Format::GCG_FASTA${version}";
    } else {
 	$class = "Parse::Format::FASTA${version}";
    }
    $type = "${class}::$prog";

    #warn "\nprog=$prog  version=$version (GCG=$GCG) type= $type\n";

    ($prog = $type) =~ s/::/\//g; require "$prog.pm";

#    if ($GCG) {
	no strict 'refs';
        $self = &{"${class}::new"}($type, undef, $text, $offset, $bytes);
#    } else {
#	$self = new($type, undef, $text, $offset, $bytes);
#    }

    $self->{'format'}  = $format;
    $self->{'version'} = $version;

    $self;
}
	    
#Parse one entry: generic for all FASTA[12]
#(FASTA3 $HIT_START definition conflicts)
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
package Parse::Format::FASTA::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package Parse::Format::FASTA::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my ($hit, $field);
    Parse::Record::print $self, $indent;
    foreach $hit (@{$self->{'hit'}}) {
	foreach $field (sort keys %$hit) {
	    printf "$x%20s -> %s\n", $field,  $hit->{$field};
	}
    }
}


###########################################################################
package Parse::Format::FASTA::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Universal::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Parse::Record_Stream($self, 0, undef);

    $line = $text->scan_lines(0);

    $self->{'trailer'} = $line;
    
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package Parse::Format::FASTA::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

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
	if ($line =~ /$SUM_START/o) {
	    $text->scan_until_inclusive($SUM_END, 'SUM');
	    next;
	}

	#fragment hits: terminated by several possibilities
	if ($line =~ /$ALN_START/o) {
	    $text->scan_until($ALN_END, 'ALN');
	    next;
	}
	
	#blank line or empty record: ignore
        next    if $line =~ /$NULL/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package Parse::Format::FASTA::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package Parse::Format::FASTA::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

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

    my ($query_start, $query_stop, $sbjct_start, $sbjct_stop) = (0,0,0,0);
    my ($query_leader,$query_trailer,$sbjct_leader,$sbjct_trailer) = (0,0,0,0);
    my ($query_length, $sbjct_length, $query_orient, $sbjct_orient);
    my ($query, $align, $sbjct, $len) = ('','','');
    my ($x, $querykey, $sbjctkey, $depth);

    #first record
    my @tmp = ();

    #warn $text->inspect_stream;

    $line = $text->next_line(1);

    #query ruler: parser requires one for the first line
    if ($line =~ /\s*\d+/) {
	$tmp[0] = $line;                  #query ruler
	$tmp[1] = $text->next_line(1);    #query sequence
	$tmp[2] = $text->next_line(1);    #match pattern
	$tmp[3] = $text->next_line(1);    #sbjct sequence
	$tmp[4] = $text->next_line(1);    #sbjct ruler

        #determine depth of sequence labels at left: take the shorter
	#since either sequence may begin with a gap
	$tmp[1] =~ /^(\s*\S+\s*)/;
	$depth = length $1;
	$tmp[3] =~ /^(\s*\S+\s*)/;
        $x = length $1;
	$depth = ($depth < $x ? $depth : $x);
	
	#recover sequence row names
	$querykey = substr($tmp[1], 0, $depth);
	$sbjctkey = substr($tmp[3], 0, $depth);
	
	#strip leading name
	$tmp[1] = substr($tmp[1], $depth);
	$tmp[2] = substr($tmp[2], $depth);
	$tmp[3] = substr($tmp[3], $depth);
	
	#warn "###$tmp[0]\n";
	#warn "###$tmp[1]\n";
	#warn "###$tmp[2]\n";
	#warn "###$tmp[3]\n";
	#warn "###$tmp[4]\n";

    } else {
	$self->die("unexpected line: $line\n");
    }

    #query/sbjct/match lines
    #warn "|$tmp[1]|\n|$tmp[2]|\n|$tmp[3]|\n";
    $len = Universal::max(length($tmp[1]), length($tmp[3]));
    $tmp[1] .= ' ' x ($len-length $tmp[1])    if length $tmp[1] < $len;
    $tmp[2] .= ' ' x ($len-length $tmp[2])    if length $tmp[2] < $len;
    $tmp[3] .= ' ' x ($len-length $tmp[3])    if length $tmp[3] < $len;
    $query = $tmp[1];
    $align = $tmp[2];
    $sbjct = $tmp[3];
    

    #initialise query length
    $x = $tmp[1]; $x =~ tr/- //d; $query_length = length($x);

    #first query start/stop, if any
    if ($tmp[0] =~ /^\s*(\d+)/) {
	$query_start = $1;
    }
    if ($tmp[0] =~ /(\d+)\s*$/) {
	$query_stop  = $1;
    }
    
    #compute length of query before query_start label
    $x = index($tmp[0], $query_start) + length($query_start) -1;
    $x = substr($tmp[1], 0, $x-$depth);    #whole leader
    $x =~ tr/- //d;                     #leader minus gaps
    $query_leader = length($x);


    #initialise sbjct length
    $x = $tmp[3]; $x =~ tr/- //d; $sbjct_length = length($x);

    #first sbjct start/stop, if any
    if ($tmp[4] =~ /^\s*(\d+)/) {
	$sbjct_start = $1;
    }
    if ($tmp[4] =~ /(\d+)\s*$/) {
	$sbjct_stop  = $1;
    }

    #compute length of sbjct before sbjct_start label
    $x = index($tmp[4], $sbjct_start) + length($sbjct_start) -1;
    $x = substr($tmp[3], 0, $x-$depth);    #whole leader
    $x =~ tr/- //d;                     #leader minus gaps
    $sbjct_leader = length($x);


    #warn "ENTRY ($querykey, $sbjctkey)\n";
    #warn "($query_length/$query_leader) ($sbjct_length/$sbjct_leader)\n";

    #remaining records
    while (defined ($line = $text->next_line(1))) {

	next if $line =~ /^\s*$/;

	@tmp = ();

	if ($line =~ /^\s*\d+/) {
	    #query ruler
	    #warn "QUERY+RULER\n";

	    $tmp[0] = $line;                     #query ruler
	    
	    $line = $text->next_line(1);
	    $tmp[1] = substr($line, $depth);     #query sequence

	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[2] = substr($line, $depth); #match pattern
	    } else {
		$tmp[2] = ' ' x length $tmp[1];
	    }

	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[3] = substr($line, $depth); #sbjct sequence
	    } else {
		$tmp[3] = ' ' x length $tmp[1];
	    }
	    
	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[4] = $line;                 #sbjct ruler
	    } else {
		$tmp[4] = '';
	    }

	} elsif (index($line, $querykey) == 0) {
	    #query sequence (no ruler)
	    #warn "QUERY (####)\n";

	    $tmp[1] = substr($line, $depth);     #query sequence

	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[2] = substr($line, $depth); #match pattern
	    } else {
		$tmp[2] = ' ' x length $tmp[1];
	    }

	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[3] = substr($line, $depth); #sbjct sequence
	    } else {
		$tmp[3] = ' ' x length $tmp[1];
	    }
	    
	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[4] = $line;                 #sbjct ruler
	    } else {
		$tmp[4] = '';
	    }

	    $tmp[0] = '';

	} elsif (index($line, $sbjctkey) == 0) {
	    #sbjct sequence
	    
	    #warn "SBJCT (####)\n";

	    if ($line) {
		$tmp[3] = substr($line, $depth); #sbjct sequence
	    } else {
		$tmp[3] = ' ' x length $tmp[1];
	    }
	    
	    $line = $text->next_line(1);
	    if ($line) {
		$tmp[4] = $line;                 #sbjct ruler
	    } else {
		$tmp[4] = '';
	    }

	    $tmp[0] = '';
	    $tmp[1] = ' ' x length $tmp[3];
	    $tmp[2] = ' ' x length $tmp[3];

	} else {
	    $self->die("unexpected line: $line\n");
	}

	#warn "###$tmp[0]\n";
	#warn "###$tmp[1]\n";
	#warn "###$tmp[2]\n";
	#warn "###$tmp[3]\n";
	#warn "###$tmp[4]\n";

	#subsequent query start/stop, if any
	if ($query_start < 1 and $tmp[0] =~ /^\s*(\d+)/) {
	    $query_start = $1;
	}
	if ($query_stop  < 1 and $tmp[0] =~ /(\d+)\s*$/) {
	    $query_stop  = $1;
	}
    
	#subsequent sbjct start/stop, if any
	if ($sbjct_start < 1 and $tmp[4] =~ /^\s*(\d+)/) {
	    $sbjct_start = $1;
	}
	if ($sbjct_stop  < 1 and $tmp[4] =~ /(\d+)\s*$/) {
	    $sbjct_stop  = $1;
	}

	#increment query length
	$x = $tmp[1]; $x =~ tr/- //d; $query_length += length($x);

	#increment sbjct length
	$x = $tmp[3]; $x =~ tr/- //d; $sbjct_length += length($x);

	#query/sbjct/match lines
	#warn "|$tmp[1]|\n|$tmp[2]|\n|$tmp[3]|\n";
	$len = Universal::max(length($tmp[1]), length($tmp[3]));
	if (length $tmp[1] < $len) {
	    $tmp[1] .= ' ' x ($len-length $tmp[1]);
	}
	if (length $tmp[2] < $len) {
	    $tmp[2] .= ' ' x ($len-length $tmp[2]);
	}
	if (length $tmp[3] < $len) {
	    $tmp[3] .= ' ' x ($len-length $tmp[3]);
	}
	$query .= $tmp[1];
	$align .= $tmp[2];
	$sbjct .= $tmp[3];
	
	#warn "($query_length) ($sbjct_length)\n";
    }
    
    #warn "$query\n$sbjct\n";
    #warn $text->inspect_stream;

    #warn "LAST ($query_start, $query_stop, $query_length, $query_leader)\n";
    #warn "LAST ($sbjct_start, $sbjct_stop, $sbjct_length, $sbjct_leader)\n";

    #determine query orientation and adjust query start/stop
    if ($query_start < $query_stop) {
	$query_orient = '+';
        $query_start -= $query_leader;
        $query_stop   = $query_start + $query_length -1;
    } else {
        $query_orient = '-';
        $query_start += $query_leader;
        $query_stop   = $query_start - $query_length +1;
    }

    #determine sbjct orientation and adjust sbjct start/stop
    if ($sbjct_start < $sbjct_stop) {
	$sbjct_orient = '+';
        $sbjct_start -= $sbjct_leader;
        $sbjct_stop   = $sbjct_start + $sbjct_length -1;
    } else {
        $sbjct_orient = '-';
        $sbjct_start += $sbjct_leader;
        $sbjct_stop   = $sbjct_start - $sbjct_length +1;
    }

    #warn "EXIT ($query_orient, $query_start, $query_stop) ($sbjct_orient, $sbjct_start, $sbjct_stop)\n";

    #query_leader/query_trailer
    $query =~ /^(\s*)/;
    $query_leader   = length $1;
    $query =~ /(\s*)$/;
    $query_trailer  = length $1;
    
    #sbjct_leader/sbjct_trailer
    $sbjct =~ /^(\s*)/;
    $sbjct_leader   = length $1;
    $sbjct =~ /(\s*)$/;
    $sbjct_trailer  = length $1;
    
    $self->{'query'} = $query;
    $self->{'align'} = $align;
    $self->{'sbjct'} = $sbjct;

    $self->{'query_orient'}  = $query_orient;
    $self->{'query_start'}   = $query_start;
    $self->{'query_stop'}    = $query_stop;
    $self->{'query_leader'}  = $query_leader;
    $self->{'query_trailer'} = $query_trailer;

    $self->{'sbjct_orient'}  = $sbjct_orient;
    $self->{'sbjct_start'}   = $sbjct_start;
    $self->{'sbjct_stop'}    = $sbjct_stop;
    $self->{'sbjct_leader'}  = $sbjct_leader;
    $self->{'sbjct_trailer'} = $sbjct_trailer;

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n", 'query',          $self->{'query'};
    printf "$x%20s -> '%s'\n", 'align',          $self->{'align'};
    printf "$x%20s -> '%s'\n", 'sbjct',          $self->{'sbjct'};
    printf "$x%20s -> %s\n",   'query_orient',   $self->{'query_orient'};
    printf "$x%20s -> %s\n",   'query_start',    $self->{'query_start'};
    printf "$x%20s -> %s\n",   'query_stop',     $self->{'query_stop'};
    printf "$x%20s -> %s\n",   'query_leader',   $self->{'query_leader'};
    printf "$x%20s -> %s\n",   'query_trailer',  $self->{'query_trailer'};
    printf "$x%20s -> %s\n",   'sbjct_orient',   $self->{'sbjct_orient'};
    printf "$x%20s -> %s\n",   'sbjct_start',    $self->{'sbjct_start'};
    printf "$x%20s -> %s\n",   'sbjct_stop' ,    $self->{'sbjct_stop'};
    printf "$x%20s -> %s\n",   'sbjct_leader',   $self->{'sbjct_leader'};
    printf "$x%20s -> %s\n",   'sbjct_trailer',  $self->{'sbjct_trailer'};
}


###########################################################################
1;
