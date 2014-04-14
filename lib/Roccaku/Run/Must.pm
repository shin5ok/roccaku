package Roccaku::Run::Must;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base qw( Roccaku::Run::Base );

sub favor {
  my ($self, @args) = @_;

  for my $arg ( @args ) {
    if (ref $arg eq q{HASH}) {
      while (my ($method, $value) = each %$arg) {
        $self->$method( $value );
      }
    } else {
      $self->command( $arg );
    }
  }
}

sub file {
  my ($self, $argv) = @_;
  open my $fh, "<", $argv->{path};
  if (! $fh) {
    $self->fail("$argv->{path} cannot open");
    return 0;
  }

  my @patterns = ref $argv->{pattern} eq q{ARRAY}
               ? @{$argv->{pattern}
               : ( $argv->{pattern} );

  my @contents = <$fh>;
  my $failure = 0;
  for my @$pattern ( @patterns ) {
    if (! grep /$pattern/ @contents) {
      $self->fail("$argv->{path} don't have line $pattern");
      $failure++;
    }
  }
  return $self;

  return $failure == 0;

}

1; # End of Roccaku::Must;
