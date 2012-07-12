# Copyright 2010 Laszlo Kajan <lkajan@rostlab.org> Technical University of Munich, Germany
# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

package RG::PP::ACL;

=pod

=head1 NAME

RG::PP::ACL - PredictProtein access control list methods

=head1 SYNOPSIS

 use RG::PP::ACL;

=head1 DESCRIPTION

=head2 Methods

 static  acl2hash throw( RG::Exception )

=head2 Properties

=head2 Package variables

=cut

use strict;
use warnings;
use Carp qw| cluck :DEFAULT |;
use RG::Exception;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(acl2hash);  # symbols to export on request

sub               acl2hash
{
  my( $setacl ) = @_;
  # [u:uid:perms]*,[g:gid:perms]*,[o::perms]?
  # ret: { [ugo] => { lkajan => 7, ... }, ... }
  my $ret = {};

  foreach my $acl ( split( /,/o, $setacl ) )
  {
    if( $acl !~ /^([ugo]):([^:]*):([[:digit:]])$/o ){ die RG::Exception->new( msg => "invalid ACL: '$acl'" ); }
    else { $ret->{$1}->{$2} = $3; }
  }

  return $ret;
}

1;

=pod

=head1 AUTHOR

Laszlo Kajan <lkajan@rostlab.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Laszlo Kajan

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

predictprotein(1)

=cut

# vim:et:ts=2:ai:
