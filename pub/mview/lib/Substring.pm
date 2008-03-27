# Copyright (c) 1996-1999  Nigel P. Brown, All rights reserved. $Id: Substring.pm,v 1.2 1999/01/26 23:04:14 nbrown Exp $

###########################################################################
package Substring;

use vars qw(@ISA);
use Universal;
use strict;

@ISA = qw(Universal);

$Substring::Debug = 0;

sub new {
    my $type = shift;
    #warn "${type}::new()\n"    if $Substring::Debug;
    Universal::die($type, "new() invalid argument list (@_)")    if @_ < 1;
    return new Substring::String(@_)    if ref $_[0];    #arg = string ref
    new Substring::File(@_);                             #arg = filename
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub get_file   {''}
sub get_length {$_[0]->{'extent'}}
sub get_base   {$_[0]->{'base'}}


###########################################################################
package Substring::File;

use vars qw(@ISA);
use POSIX;
use FileHandle;
use strict;

@ISA = qw(Substring);

$Substring::File::open  = 1;
$Substring::File::close = 2;
$Substring::File::error = 4;

sub new {
    my $type = shift;
    #warn "${type}::new()\n"    if $Substring::Debug;
    my ($file, $base) = (@_, 0);
    my $self = {};
    bless $self, $type;

    $self->{'file'}   = $file;
    $self->{'base'}   = $base;
    $self->{'state'}  = $Substring::File::close;
    $self->{fh}     = -1;

    $self->_open;

    #find file extent
    #$self->{fh}->seek(0, SEEK_END);
    #$self->{'extent'} = $self->{fh}->tell;
    $self->{'extent'} = (stat $self->{fh})[7];

    $self;
}

sub get_file   {$_[0]->{'file'}}

sub close {
    #warn "close()\n"    if $Substring::Debug;
    $_[0]->_close;
}

sub open {
    #warn "open()\n"    if $Substring::Debug;
    $_[0]->reopen(@_);
}

sub reopen {
    my $self = shift;
    #warn "reopen()\n"    if $Substring::Debug;
    if ($self->{'state'} & $Substring::File::error or $self->{'state'} & $Substring::File::open) {
	$self->_close;
    }
    $self->_open;
    $self->_reset;
    $self;	
}

sub reset {
    my $self = shift;
    #warn "reset()\n"    if $Substring::Debug;
    if ($self->{'state'} & $Substring::File::error) {
	$self->_close;
	$self->_open;
    } elsif ($self->{'state'} & $Substring::File::close) {
	$self->_open;
    }
    $self->_reset;
    $self;	
}

sub _seek {
    my ($self, $new) = @_;
    my $old = $self->{fh}->tell;
    if ($new < $old) {
	#seek nearer BASE of file
	if ($old - $new < $new) {
	    #warn "seek BACKWARDS  from OLD    by ($old - $new) bytes\n"    if $Substring::Debug;
	    seek($self->{fh}, $new-$old, SEEK_CUR);
	} else {
	    #warn "seek FORWARDS   from BASE   by ($new) bytes\n"    if $Substring::Debug;
	    seek($self->{fh}, $new, SEEK_SET);
	}
	return;
    } elsif ($old < $new) {
	#seek nearer EXTENT of file
	if ($new - $old < $self->{'extent'} - $new) {
	    #warn "seek FORWARDS   from OLD    by ($new - $old) bytes\n"    if $Substring::Debug;
	    seek($self->{fh}, $new-$old, SEEK_CUR);
	} else {
	    #warn "seek BACKWARDS  from EXTENT by ($self->{'extent'} - $new) bytes\n"    if $Substring::Debug;
	    seek($self->{fh}, $new-$self->{'extent'}, SEEK_END);
	}
	return;
    }
    #don't seek - already there!
    #warn "seek nowhere\n"    if $Substring::Debug;
    return;
}

sub _reset {
    my $self = shift;
    #warn " _reset()\n"    if $Substring::Debug;
    $self->{fh}->seek($self->{'base'}, SEEK_SET);
    $self;
}

sub _close {
    my $self = shift;
    #warn " _close()\n"    if $Substring::Debug;
    $self->{fh}->close;
    $self->{fh} = -1;
    $self->{'state'} = $Substring::File::close;
    $self;
}

sub _open {
    my $self = shift;
    #warn " _open()\n"    if $Substring::Debug;
    $self->{fh} = new FileHandle    if $self->{fh} < 1;
    $self->{fh}->open($self->{'file'}) or $self->die("_open() can't open ($self->{'file'})");
    $self->{'state'} = $Substring::File::open;
    $self;
}

sub substr {
    my $self = shift;
    #warn " substr(@_)\n"    if $Substring::Debug;
    if ($self->{'state'} & $Substring::File::close) {
	$self->die("substr() can't read on closed file '$self->{'file'}'");
    }
    my ($offset, $bytes) = (@_, $self->{'base'}, $self->{'extent'}-$self->{'base'});
    my $buff = '';
    $self->_seek($offset);
    read($self->{fh}, $buff, $bytes);
    $buff;
}

sub getline {
    my $self = shift;
    #warn " getline()\n"    if $Substring::Debug;
    my ($offset) = (@_, $self->{'base'});
    my $fh = $self->{fh};
    $self->_seek($offset);
    return <$fh>;
}


###########################################################################
# A wrapper for a string held in memory to mimic a Substring::File

package Substring::String;

use vars qw(@ISA);
use Universal;
use strict;

@ISA = qw(Substring);

sub new {
    my $type = shift;
    #warn "${type}::new()\n"    if $Substring::Debug;
    my $self = {};
    ($self->{'text'}, $self->{'base'}) = (@_, 0);
    $self->{'extent'} = length ${$self->{'text'}};
    bless $self, $type;
}

sub close  {$_[0]}
sub open   {$_[0]}
sub reopen {$_[0]}
sub reset  {$_[0]}

sub substr {
    my $self = shift;
    my ($offset, $bytes) = (@_, $self->{'base'}, 
			    $self->{'extent'}-$self->{'base'});
    substr(${$self->{'text'}}, $offset, $bytes);
}

sub getline {
    my $self = shift;
    my ($offset) = (@_, $self->{'base'});
    my $i = index(${$self->{'text'}}, "\n", $offset);
    return CORE::substr(${$self->{'text'}}, $offset, $i-$offset+1) if $i > -1;
    return CORE::substr(${$self->{'text'}}, $offset);
}


###########################################################################
1;
