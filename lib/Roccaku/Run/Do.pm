package Roccaku::Run::Do;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base qw( Roccaku::Run::Base );

# sub favor {
#   shift->SUPER::favor;
# }

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
  seek $fh, 0, 0;
  flock $fh, 2;

  my @contents = <$fh>;
  my @patterns = ref $argv->{pattern} eq q{ARRAY}
               ? @{$argv->{pattern}}
               : ( $argv->{pattern} );

  my $failure = 0;
  local $@;
  eval {
    for my $pattern ( @patterns ) {
      if (! grep m{$pattern}, @contents) {
        $self->fail("$argv->{path} don't have $pattern in any lines");
        $failure++;
      }
    }
  };
  warn $@ if $@;

  return $failure == 0;

}

1; # End of Roccaku::Do;
