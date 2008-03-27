# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: Stream.pm,v 1.2 1999/01/26 23:18:16 nbrown Exp $

###########################################################################
package Parse::Stream;

use vars qw(@ISA);
use FileHandle;
use Parse::Record;
use Substring;
use strict;

@ISA = qw(Universal);

#assumes a stream doesn't mix formats
sub new {
    my $type = shift;
    my ($file, $format) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'fh'} = new FileHandle;
    $self->{'fh'}->open($file) or $self->die("new() can't open '$file'");

    $self->{'file'}   = $file;
    $self->{'format'} = $format;
    $self->{'text'}   = new Substring($file);

    ($file = "Parse::Format::$format") =~ s/::/\//g;
    require "$file.pm";

    $self;
}

sub get_file   { $_[0]->{'file'} }
sub get_format { $_[0]->{'format'} }
sub get_length { $_[0]->{'text'}->get_length }

sub get_entry {
    no strict 'refs';
    my $e = &{"Parse::Format::$_[0]->{'format'}::get_entry"}(@_);
    return undef    unless $e;
    $e;
}

sub print {
    my $self = shift;
    $self->examine(qw(file format));
} 

sub close { 
    $_[0]->{'text'}->close; 
    $_[0]->{'fh'}->close;
}

sub DESTROY { $_[0]->close }


###########################################################################
1;
