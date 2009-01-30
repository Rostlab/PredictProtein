package PP_Checkpoint;
require Exporter;
use Storable;

@ISA = qw(Exporter);
@EXPORT_OK = qw( );  # symbols to export on request

sub mkcheckpoint
{
  # { ref: reference, fh: GLOBref }
  my( $__p ) = @_;

  eval {
    nstore_fd( $__p->{'ref'}, $__p->{fh} );
  };
  if( $@ ) { warn; }
}

sub restorecheckpoint
{
  # { fh: GLOBref }
  my( $__p ) = @_;

  return fd_retrieve( $__p->{fh} );
}

1;
# vim:et:ts=2:ai:
