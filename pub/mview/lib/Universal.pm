# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown, All rights reserved. $Id: Universal.pm,v 1.19 1999/01/26 23:04:15 nbrown Exp $

######################################################################
package Universal;

#useful general stuff
$::Date = `date`;
$::Prog = basename($0);

use strict;

#sub member {
#    my ($pattern, $list) = @_;
#
#    if (scalar(grep(/^$pattern$/, @$list)) != 1) {
#       $pattern = '\\' . $pattern;
#       if (scalar(grep(/^$pattern$/, @$list)) != 1) {
#           return 0;
#       }
#    }
#    return 1;
#}

sub member {
    my ($pattern, $list) = @_;
    my $i;
    foreach $i (@$list) {
        return 1    if $i eq $pattern;
    }
    return 0;
}

#dump sorted list of all instance variables, or supplied list
sub examine {
    my $self = shift;
    my @keys = @_ ? @_ : sort keys %$self;
    my $key;
    print "Class $self\n";
    foreach $key (@keys) {
        printf "%16s => %s\n", $key,
	    defined $self->{$key} ? $self->{$key} : '';
    }
    $self;
}

#shallow copy
sub copy {
    my $self = shift;
    my $copy = {};
    local $_;
    foreach (keys %$self) {
	#warn "$_ => $self->{$_}\n";
	if (defined $self->{$_}) {
	    $copy->{$_} = $self->{$_};
	} else {
	    $copy->{$_} = '';
	}
    }
    bless $copy, ref $self;
}

#deep copy
sub deep_copy {
    my $self = shift;
    my $copy = {};
    my $type;
    local $_;
    foreach (keys %$self) {
	#warn "$_ => $self->{$_}\n";
	if (defined $self->{$_}) {
	    if ($type = ref $self->{$_}) {
		if (UNIVERSAL::member($type, { qw(SCALAR ARRAY HASH CODE)})) {
		    $copy->{$_} = $self->{$_};
		} else {
		    $copy->{$_} = $copy->{$_}->deep_copy;
		}
	    }
	    $copy->{$_} = $self->{$_};
	} else {
	    $copy->{$_} = '';
	}
    }
    bless $copy, ref $self;
}

#warn with error string
sub warn {
    my $self = shift;
    chomp $_[$#_];
    if (ref($self)) {
	warn "Warning ", ref($self), '::', @_, "\n";
	return;
    }
    warn "Warning ", $self, '::', @_, "\n";
}

#exit with error string
sub die {
    my $self = shift;
    chomp $_[$#_];
    if (ref($self)) {
	die "Died ", ref($self), '::', @_, "\n";
    }
    die "Died ", $self, '::', @_, "\n";
}

#replacement for /bin/basename
sub basename {
    my($path, $ext) = (@_, "");
    ($path) = "/$path" =~ /.*\/(.+)$/;
    if ($path =~ /(.*)$ext$/) {
        return $1;
    }
    $path;
}

#arithmetic min() function
sub min {
    my ($a, $b) = @_;
    $a < $b ? $a : $b;
}


#arithmetic max() function
sub max {
    my ($a, $b) = @_;
    $a > $b ? $a : $b;
}

#Linux only?
sub vmstat {
    my ($s) = (@_, '');
    local ($_, *TMP);
    if (open(TMP, "cat /proc/$$/stat|")) {
	$_=<TMP>; my @ps = split /\s+/; close TMP;
	CORE::warn sprintf "VMEM=%8gk  $s\n", $ps[22] / 1024;
    } else {
	CORE::warn sprintf "VMEM=?  $s\n";
    }
}


######################################################################
1;
