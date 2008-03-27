# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: blastn.pm,v 1.3 1999/09/03 16:34:01 nbrown Exp $

###########################################################################
package Parse::Format::BLAST2::blastn;

use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2);


###########################################################################
package Parse::Format::BLAST2::blastn::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HEADER);


###########################################################################
package Parse::Format::BLAST2::blastn::SEARCH;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH);


###########################################################################
package Parse::Format::BLAST2::blastn::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH::RANK);


###########################################################################
package Parse::Format::BLAST2::blastn::SEARCH::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT);


###########################################################################
package Parse::Format::BLAST2::blastn::SEARCH::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT::SUM);


###########################################################################
package Parse::Format::BLAST2::blastn::SEARCH::HIT::ALN;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::BLAST2::SEARCH::HIT::ALN);

sub new {
    my $type = shift;
    my ($parent) = @_;
    my $self = new Parse::Format::BLAST2::SEARCH::HIT::ALN(@_);
    bless $self, $type;

    #use sequence numbering to get orientations; ignore
    #explicit orientations or frames in BLAST[NX] 2.0.9
    if ($self->{'query_start'} > $self->{'query_stop'}) {
	$self->{'query_orient'} = '-';
    } else {
	$self->{'query_orient'} = '+';
    }
    if ($self->{'sbjct_start'} > $self->{'sbjct_stop'}) {
	$self->{'sbjct_orient'} = '-';
    } else {
	$self->{'sbjct_orient'} = '+';
    }

    #record paired orientations in HIT list
    push @{$parent->{'orient'}->{
				 $self->{'query_orient'} .
				 $self->{'sbjct_orient'}
				}}, $self;
    
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %s\n",   'query_orient',   $self->{'query_orient'};
    printf "$x%20s -> %s\n",   'sbjct_orient',   $self->{'sbjct_orient'};
    $self->SUPER::print($indent);
}


###########################################################################
package Parse::Format::BLAST2::blastn::WARNING;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::WARNING);


###########################################################################
package Parse::Format::BLAST2::blastn::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
