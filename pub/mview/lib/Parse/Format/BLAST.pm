# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: BLAST.pm,v 1.4 1999/09/13 17:15:16 nbrown Exp $

###########################################################################
#
# Base classes for NCBI BLAST1, WashU BLAST2, NCBI BLAST2 families.
#
###########################################################################
package Parse::Format::BLAST;

use vars qw(@ISA $GCG_JUNK);
use strict;

@ISA = qw(Parse::Record);

BEGIN { $GCG_JUNK = '(?:^\.\.|^\\\\)' }

use Parse::Format::BLAST1;
use Parse::Format::BLAST2;

my %VERSIONS = (
		@Parse::Format::BLAST1::VERSIONS,
		@Parse::Format::BLAST2::VERSIONS,
	       );
 			 
my $NULL        = '^\s*$';#for emacs';
    
my $ENTRY_START = "(?:"
    . $Parse::Format::BLAST1::ENTRY_START
    . "|"
    . $Parse::Format::BLAST2::ENTRY_START
    . ")";
my $ENTRY_END   = "(?:"
    . $Parse::Format::BLAST1::ENTRY_END
    . "|"
    . $Parse::Format::BLAST2::ENTRY_END
    . ")";

my $HEADER_START = "(?:"
    . $Parse::Format::BLAST1::HEADER_START
    . "|"
    . $Parse::Format::BLAST2::HEADER_START
    . ")";
my $HEADER_END   = "(?:"
    . $Parse::Format::BLAST1::HEADER_END
    . "|"
    . $Parse::Format::BLAST2::HEADER_END
    . ")";

my $PARAMETERS_START = "(?:"
    . $Parse::Format::BLAST1::PARAMETERS_START
    . "|"
    . $Parse::Format::BLAST2::PARAMETERS_START
    . ")";
my $PARAMETERS_END = "(?:"
    . $Parse::Format::BLAST1::PARAMETERS_END
    . "|"
    . $Parse::Format::BLAST2::PARAMETERS_END
    . ")";

my $WARNINGS_START = "(?:"
    . $Parse::Format::BLAST1::WARNINGS_START
    . "|"
    . $Parse::Format::BLAST2::WARNINGS_START
    . ")";
my $WARNINGS_END = "(?:"
    . $Parse::Format::BLAST1::WARNINGS_END
    . "|"
    . $Parse::Format::BLAST2::WARNINGS_END
    . ")";

my $HISTOGRAM_START = "(?:"
    . $Parse::Format::BLAST1::HISTOGRAM_START
    . ")";
my $HISTOGRAM_END = "(?:"
    . $Parse::Format::BLAST1::HISTOGRAM_END
    . ")";

my $RANK_START = "(?:"
    . $Parse::Format::BLAST1::RANK_START
    . "|"
    . $Parse::Format::BLAST2::RANK_START
    . ")";
my $RANK_END = "(?:"
    . $Parse::Format::BLAST1::RANK_END
    . "|"
    . $Parse::Format::BLAST2::RANK_END
    . ")";

my $HIT_START = "(?:"
    . $Parse::Format::BLAST1::HIT_START
    . "|"
    . $Parse::Format::BLAST2::HIT_START
    . ")";
my $HIT_END = "(?:"
    . $Parse::Format::BLAST1::HIT_END
    . "|"
    . $Parse::Format::BLAST2::HIT_END
    . ")";

my $WARNING_START = "(?:"
    . $Parse::Format::BLAST1::WARNING_START
    . "|"
    . $Parse::Format::BLAST2::WARNING_START
    . ")";
my $WARNING_END = "(?:"
    . $Parse::Format::BLAST1::WARNING_END
    . "|"
    . $Parse::Format::BLAST2::WARNING_END
    . ")";

my $SEARCH_START = "(?:"
    . $Parse::Format::BLAST2::SEARCH_START
    . ")";
my $SEARCH_END = "(?:"
    . $Parse::Format::BLAST2::SEARCH_END
    . ")";

my $SCORE_START = "(?:"
    . $Parse::Format::BLAST1::SCORE_START
    . "|"
    . $Parse::Format::BLAST2::SCORE_START
    . ")";
my $SCORE_END = "(?:"
    . $Parse::Format::BLAST1::SCORE_END
    . "|"
    . $Parse::Format::BLAST2::SCORE_END
    . ")";

#Generic get_entry() and new() constructors for all BLAST style parsers:
#determine program and version and coerce appropriate subclass.

#Consume one entry-worth of input on stream $fh associated with $file and
#return a new BLAST instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};

    my ($type, $prog, $version) = ('Parse::Format::BLAST', undef, undef);
    
    my ($saveformat, $saveversion) = ('', '');

    while (defined ($line = <$fh>)) {
	
	#start of entry
	if ($line =~ /$ENTRY_START/o and $offset < 0) {
	    $offset = $fh->tell - length($line);
	    #fall through for version tests
	}

	#end of entry
	last    if $line =~ /$ENTRY_END/o;

	#escape iteration if we've found the BLAST type previously
	next    if defined $prog and defined $version;
	
	if ($line =~ /$HEADER_START\s+(\d+)/o) {

	    #read major version
	    $version = $1;

	    #reassess version
	    if ($line =~ /WashU/) {
		#WashU series is almost identical to NCBI BLAST1
		$version = 1;
	    }
	    
	    #read program name
	    $line =~ /^\s*(\S+)/;
	    $prog = $1;

	    $saveformat  = uc $prog;
	    $saveversion = $version;
		
	    next;
	}
	
    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    unless (defined $prog and defined $version) {
	die "get_entry() top-level BLAST parser could not determine program/version\n";
    }

    unless (exists $VERSIONS{$version} and 
	    grep(/^$prog$/i, @{$VERSIONS{$version}}) > 0) {
	die "get_entry() parser for program '$prog' version '$version' not implemented\n";
    }

    $prog = lc $prog;
    $version =~ s/-/_/g;
    $type = "Parse::Format::BLAST${version}::$prog";

    #warn "prog= $prog  version= $version  type= $type\n";
    
    ($prog = $type) =~ s/::/\//g; require "$prog.pm";

    #package $type defines this constructor and coerces to $type

    my $self = $type->new(undef, $text, $offset, $bytes);

    $self->{'format'}  = $saveformat;
    $self->{'version'} = $saveversion;

    $self;
}
    
sub new { die "$_[0]::new() virtual function called\n" }


###########################################################################
package Parse::Format::BLAST::HEADER;

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

    $self->{'query'}   = '';
    $self->{'summary'} = '';

    while ($line = $text->next_line) {
    
	#blast version info
	if ($line =~ /($HEADER_START\s+(\S+).*)/o) {
	
	    $self->test_args($line, $1, $2);
	    
	    (
	     $self->{'full_version'},
	     $self->{'version'},
	    ) = ($1, $2);
	    
	    next;
	} 

	#query line
	if ($line =~ /^Query=\s+(\S+)?\s*[,;]?\s*(.*)/) {
	    
	    #no test - either field may be missing

	    $self->{'query'}   = $1    if defined $1;
	    $self->{'summary'} = $2    if defined $2;

	    #strip leading unix path stuff
            $self->{'query'} =~ s/.*\/([^\/]+)$/$1/;

	    next;
	} 

	#ignore any other text
    }
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n", 'version',        $self->{'version'};
    printf "$x%20s -> %s\n", 'full_version',   $self->{'full_version'};
    printf "$x%20s -> %s\n", 'query',          $self->{'query'};
    printf "$x%20s -> %s\n", 'summary',        $self->{'summary'};
}


###########################################################################
package Parse::Format::BLAST::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my ($hit, $field);
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n", 'header',        $self->{'header'};
    foreach $hit (@{$self->{'hit'}}) {
	foreach $field (sort keys %$hit) {
	    printf "$x%20s -> %s\n", $field,  $hit->{$field};
	}
    }
}


###########################################################################
package Parse::Format::BLAST::HIT;

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

    #strand orientations, filled by HIT::ALN object
    $self->{'orient'} = {};

    while (defined ($line = $text->next_line)) {

	#identifier lines
	if ($line =~ /$HIT_START/o) {
	    $text->scan_until($NULL, 'SUM');
	    next;
	}

	#scored alignments
	if ($line =~ /$SCORE_START/o) {
	    $text->scan_until($SCORE_END, 'ALN');
	    next;
	}
	
	#strand orientation: ignore
	next    if $line =~ /^  (?:Plus|Minus) Strand/;
	
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
    my $i;
    Parse::Record::print $self, $indent;
    foreach $i (keys %{$self->{'orient'}}) {
	printf("$x%20s -> %s\n",
	       "orient $i", scalar @{$self->{'orient'}->{$i}});
    }
}


###########################################################################
package Parse::Format::BLAST::HIT::SUM;

use vars qw(@ISA);
use Regexps;

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

    $line = $text->scan_lines(0);

    if ($line =~ /^\s*
	>?\s*
	([^\s]+)                            #id
	\s+
	(.*)                                #description
	\s+
	Length\s*=\s*($RX_Uint)             #length
	/xso) {
	
	$self->test_args($line, $1, $3);    #ignore $2

	(
	 $self->{'id'},
	 $self->{'desc'},
	 $self->{'length'},
	) = (Parse::Record::strip_leading_identifier_chars($1),
	     Parse::Record::strip_english_newlines($2), $3);
    }
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'id',         $self->{'id'};
    printf "$x%20s -> '%s'\n", 'desc',       $self->{'desc'};
    printf "$x%20s -> %s\n",   'length',     $self->{'length'};
}


###########################################################################
package Parse::Format::BLAST::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub parse_alignment {
    my ($self, $text) = @_;
    my ($query_start, $query_stop, $sbjct_start, $sbjct_stop) = (0,0,0,0);
    my ($query, $align, $sbjct) = ('','','');
    my ($line, $depth, $len);

    my @tmp = ();

    #alignment lines
    while (defined ($line = $text->next_line)) {
	
	#blank line or empty record: ignore
        next    if $line =~ /$NULL/o;

	#ignore this line (BLASTN)
	next    if $line =~ /^\s*(?:Plus|Minus) Strand/;

	#first compute sequence indent depth
	if ($line =~ /^(\s*Query\:?\s+(\d+)\s*)/) {
	    $depth = length($1);
	}

	#Strand orientations line (BLASTN 2.0.9)
	next    if $line =~ /^\s*Strand\s*=/;

	#Frame shift line (BLASTX 2.0.9)
	next    if $line =~ /^\s*Frame\s*=/;

	@tmp = ();

	#Query line
	if ($line =~ /^\s*
	    Query\:?
	    \s+
	    (\d+)		#start
#           \s+
	    \s*
	    ([^\d\s]+)          #sequence
	    \s+
	    (\d+)		#stop
	    /xo) {

	    $self->test_args($line, $1, $2, $3);

	    if ($query_start) {
		$query_stop = $3;
	    } else {
		($query_start, $query_stop) = ($1, $3);
	    }
	    $tmp[0] = $2;
	    
	} else {
	    $self->warn("expecting 'Query' line: $line");
	}
	
	#force read of match line, but note:
	#PHI-BLAST has an extra line - ignore for the time being
	$line = $text->next_line(1);
	$line = $text->next_line(1)  if $line =~ /^pattern/;

	$line = substr($line, $depth);

	#alignment line
	$tmp[1] = $line;
	
	#force read of Sbjct line
	$line = $text->next_line;

	#Sbjct line
	if ($line =~ /^\s*
	    Sbjct\:?
	    \s+
	    (\d+)               #start
#	    \s+
	    \s*
	    ([^\d\s]+)		#sequence
	    \s+
	    (\d+)	        #stop
	    /xo) {
	    
	    $self->test_args($line, $1, $2, $3);

	    if ($sbjct_start) {
		$sbjct_stop = $3;
	    } else {
		($sbjct_start, $sbjct_stop) = ($1, $3);
	    }
	    $tmp[2] = $2;
	    
	    #query/match/sbjct lines
	    #warn "|$tmp[0]|\n|$tmp[1]|\n|$tmp[2]|\n";
	    $len = Universal::max(length($tmp[0]), length($tmp[2]));
	    if (length $tmp[0] < $len) {
		$tmp[0] .= ' ' x ($len-length $tmp[0]);
	    }
	    if (length $tmp[1] < $len) {
		$tmp[1] .= ' ' x ($len-length $tmp[1]);
	    }
	    if (length $tmp[2] < $len) {
		$tmp[2] .= ' ' x ($len-length $tmp[2]);
	    }
	    $query .= $tmp[0];
	    $align .= $tmp[1];
	    $sbjct .= $tmp[2];
	    
	    next;               #finally we can loop

	} else {
	    $self->warn("expecting 'Sbjct' line: $line");
	}
	
	#default
	$self->warn("unknown field: $line");
    }

    if (length($query) != length($align) or length($query) != length($sbjct)) {
	$self->warn("unequal Query/align/Sbjct lengths:\n$query\n$align\n$sbjct\n");
    }

    $self->{'query'} 	   = $query;
    $self->{'align'} 	   = $align;
    $self->{'sbjct'} 	   = $sbjct;

    $self->{'query_start'} = $query_start;
    $self->{'query_stop'}  = $query_stop;
    $self->{'sbjct_start'} = $sbjct_start;
    $self->{'sbjct_stop'}  = $sbjct_stop;
    
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> '%s'\n", 'query',          $self->{'query'};
    printf "$x%20s -> '%s'\n", 'align',          $self->{'align'};
    printf "$x%20s -> '%s'\n", 'sbjct',          $self->{'sbjct'};
    printf "$x%20s -> %s\n",   'query_start',    $self->{'query_start'};
    printf "$x%20s -> %s\n",   'query_stop',     $self->{'query_stop'};
    printf "$x%20s -> %s\n",   'sbjct_start',    $self->{'sbjct_start'};
    printf "$x%20s -> %s\n",   'sbjct_stop' ,    $self->{'sbjct_stop'};
}


###########################################################################
package Parse::Format::BLAST::WARNING;

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
    $text = new Parse::Record_Stream($self, 0, undef);

    $line = $text->scan_lines(0);
    
    $self->{'warning'} = Parse::Record::strip_english_newlines($line);

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n",   'warning', $self->{'warning'};
}


###########################################################################
package Parse::Format::BLAST::HISTOGRAM;

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
    $text = new Parse::Record_Stream($self, 0, undef);

    $line = $text->scan_lines(0);
    
    ($self->{'histogram'} = $line) =~ s/\s*$/\n/;

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n",   'histogram', $self->{'histogram'};
}


###########################################################################
package Parse::Format::BLAST::PARAMETERS;

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
    $text = new Parse::Record_Stream($self, 0, undef);

    $line = $text->scan_lines(0);
    
    ($self->{'parameters'} = $line) =~ s/\s*$/\n/;

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n",   'parameters', $self->{'parameters'};
}


###########################################################################
1;
