# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: FASTA.pm,v 1.5 1999/12/01 13:11:50 nbrown Exp $

###########################################################################
#
# FASTA 1, 2, 3
#
# The fasta programs can produce different gapped alignments for the same
# database hit. These have the same identifier in the RANK section. Here,
# they are resolved by building a (unique?) key from identifier, initn, and
# init1. This Build doesn't attempt to merge such fragments as done for
# gapped BLAST, ie., each FASTA alignment is taken as a complete solution.
#
###########################################################################
package Bio::MView::Build::Format::FASTA;

use vars qw(@ISA);
use Bio::MView::Build::Search;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Search);

#the name of the underlying Parse::Format parser
sub parser { 'FASTA' }

my %Known_Parameter = 
    (
     #name        => [ format,             default ]
     'minopt'     => [ '\d+',              undef   ],

     #GCG FASTA (version 2)
     'strand'     => [ [],         	   undef   ],
	
##   'frames'     => [ [],                 undef   ],
    );

sub initialise_parameters {
    my $self = shift;
    $self->SUPER::initialise_parameters;
    $self->SUPER::initialise_parameters(\%Known_Parameter);
    $self->reset_strand;
##  $self->reset_frame;
}

sub set_parameters {
    my $self = shift;
    $self->SUPER::set_parameters(@_);
    $self->SUPER::set_parameters(\%Known_Parameter, @_);
    $self->reset_strand;
##  $self->reset_frame;
}

sub new {
    shift;    #discard type
    my $self = new Bio::MView::Build::Search(@_);
    my ($type, $p, $v, $file);

    #determine the real type from the underlying parser
    ($p, $v) = (lc $self->{'entry'}->{'format'},$self->{'entry'}->{'version'});

    $type = "Bio::MView::Build::Format::FASTA$v";
    ($file = $type) =~ s/::/\//g;
    require "$file.pm";
    
    $type .= "::$p";
    bless $self, $type;

    $self->initialise;
}

#initialise parse iteration scheduler variable(s). just do them all at once
#and don't bother overriding with specific methods. likewise the scheduler
#routines can all be defined here.
sub initialise {
    my $self = shift;
    #may define strand orientation and reading frame filters later

    #GCG FASTA strand orientation
    $self->{'strand_list'} = [ qw(+ -) ];    #strand orientations
    $self->{'do_strand'}   = undef;          #list of required strand
    $self->{'strand_idx'}  = undef;          #current index into 'do_strand'

##  #FASTA reading frame
##  $self->{'frame_list'}  = [ qw(f r) ];    #reading frames
##  $self->{'do_frames'}   = undef;          #list of required frames
##  $self->{'frame_idx'}   = undef;          #current index into 'do_frames'
##  $self->{'frame_mode'}  = undef;          #output format?

    $self->initialise_parameters;      #other parameters done last
   
    $self;
}

sub strand   { $_[0]->{'do_strand'}->[$_[0]->{'strand_idx'}-1] }
##sub frame   { $_[0]->{'do_frames'}->[$_[0]->{'frame_idx'}-1] }

sub reset_strand {
    my $self = shift;

    #initialise scheduler loops and loop counters
    if (@{$self->{'strand'}} < 1 or $self->{'strand'}->[0] eq '*') {
	#empty list  - do all strand
	$self->{'do_strand'} = [ @{$self->{'strand_list'}} ];
    } else {
	#explicit strand range
	$self->{'do_strand'} = [ @{$self->{'strand'}} ];
    }
}

##sub reset_frame {
##    my $self = shift;
##
##    #initialise scheduler loops and loop counters
##    if (! defined $self->{'do_frames'}) {
##	if (@{$self->{'frames'}} and $self->{'frames'}->[0] eq '*') {
##	    #do all frames, broken out by frame
##	    $self->{'do_frames'}  = [ @{$self->{'frame_list'}} ];
##	    $self->{'frame_mode'} = 'split';
##	} elsif (@{$self->{'frames'}}) {
##	    #explicit frame range
##	    $self->{'do_frames'}  = [ @{$self->{'frames'}} ];
##	    $self->{'frame_mode'} = 'split';
##	} else {
##	    #default: empty list  - do all frames in one pass
##	    $self->{'do_frames'}  = [ @{$self->{'frame_list'}} ];
##	    $self->{'frame_mode'} = 'flat';
##	}
##    }
##}

sub next_strand {
    my $self = shift;

    #first pass?
    $self->{'strand_idx'} = 0    unless defined $self->{'strand_idx'};
    
    #normal pass: post-increment strand counter
    if ($self->{'strand_idx'} < @{$self->{'do_strand'}}) {
	return $self->{'do_strand'}->[$self->{'strand_idx'}++];
    }

    #finished loop
    $self->{'strand_idx'} = undef;
}

##sub next_frame {
##    my $self = shift;
##
##    #first pass?
##    $self->{'frame_idx'} = 0    unless defined $self->{'frame_idx'};
##    
##    #normal pass: post-increment frame counter
##    if ($self->{'frame_idx'} < @{$self->{'do_frames'}}) {
##	return $self->{'do_frames'}->[$self->{'frame_idx'}++];
##    }
##
##    #finished loop
##    $self->{'frame_idx'} = undef;
##}
##
##sub schedule_by_frame {
##    my ($self, $next) = shift;
##    if (defined ($next = $self->next_frame)) {
##	return $next;
##    }
##    return undef;           #tell parser
##}

sub schedule_by_strand {
    my ($self, $next) = shift;
    if (defined ($next = $self->next_strand)) {
	return $next;
    }
    return undef;           #tell parser
}

#row filter
sub use_row {
    my ($self, $rank, $nid, $sid, $opt) = @_;
    my $use = $self->SUPER::use_row($rank, $nid, $sid);
    $self->use_frag($opt)  if $use == 1;
    #warn "FASTA::use_row($rank, $nid, $sid, $opt) = $use\n";
    return $use;
}

#minopt filter
sub use_frag {
    my ($self, $opt) = @_;
    return 0  if defined $self->{'minopt'} and $opt < $self->{'minopt'};
    return 1;
}

#remove query and hit columns at gaps in the query sequence and downcase
#the bounding hit symbols in the hit sequence thus affected. additionally,
#remove leading/trailing space from the query.
sub strip_query_gaps {
    my ($self, $query, $sbjct, $leader, $trailer) = @_;
    my $i;

    #warn "sqg(in  q)=[$$query]\n";
    #warn "sqg(in  h)=[$$sbjct]\n";

    #strip query gaps marked as '-'
    while ( ($i = index($$query, '-')) >= 0 ) {
	
	#downcase preceding symbol in hit
	if (defined substr($$query, $i-1, 1)) {
	    substr($$sbjct, $i-1, 1) = lc substr($$sbjct, $i-1, 1);
	}
	
	#consume gap symbols in query and hit
	while (substr($$query, $i, 1) eq '-') {
	    substr($$query, $i, 1) = "";
	    substr($$sbjct, $i, 1) = "";
	}
	
	#downcase succeding symbol in hit
	if (defined substr($$query, $i, 1)) {
	    substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
	}
    }

    #strip query terminal white space
    $trailer = length($$query) - $leader - $trailer;
    $$query  = substr($$query, $leader, $trailer);
    $$sbjct  = substr($$sbjct, $leader, $trailer);
	
    #replace sbjct leading/trailing white space with gaps
    $$sbjct =~ s/\s/-/g;

    #warn "sqg(out q)=[$$query]\n";
    #warn "sqg(out h)=[$$sbjct]\n";

    $self;
}


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build::Row);

#based on assemble_blastn() fragment processing
sub assemble_fasta {
    my $self = shift;
    my ($i, $tmp);

    #query:     protein|dna
    #database:  protein|dna
    #alignment: protein|dna x protein|dna
    #query numbered in protein|dna units
    #sbjct numbered in protein|dna units
    #query orientation: +-
    #sbjct orientation: +-

    #processing steps:
    #if query -
    #  (1) reverse assembly position numbering
    #  (2) reverse each frag
    #  (3) assemble frags
    #  (4) reverse assembly
    #if query +
    #  (1) assemble frags

    if ($self->{'query_orient'} =~ /^\-/) {
        #stage (1,2,3,4)
        $self->SUPER::assemble(@_, 1);
    } else {
        #stage (1)
        $self->SUPER::assemble(@_);
    }
    $self;
}

sub new {
    my $type = shift;
    my ($num, $id, $desc, $initn, $init1, $opt) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'initn'} = $initn;
    $self->{'init1'} = $init1;
    $self->{'opt'}   = $opt;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %5s %5s", 'initn', 'init1', 'opt') unless $_[0]->num;
    sprintf("%5s %5s %5s", $_[0]->{'initn'}, $_[0]->{'init1'}, $_[0]->{'opt'});
}

sub rdb {
    my ($self, $mode) = (@_, 'data');
    my $s = $self->SUPER::rdb($mode);
    return join("\t", $s, $self->{'initn'}, $self->{'init1'}, $self->{'opt'})
        if $mode eq 'data';
    return join("\t", $s, 'initn', 'init1', 'opt')
	if $mode eq 'attr';
    return join("\t", $s, '5N', '5N', '5N')
	if $mode eq 'form';
    '';
}


###########################################################################
1;
