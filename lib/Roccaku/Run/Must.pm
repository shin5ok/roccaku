package Roccaku::Run::Must;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use base qw( Roccaku::Run::Base );

our $__GEN_SORT = 50;

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
  my $fh;
  if (! open $fh, "<", $argv->{path}) {
    $self->fail("$argv->{path} cannot open");
    return 0;
  }

  my @contents = <$fh>;
  my @patterns = ref $argv->{pattern} eq q{ARRAY}
               ? @{$argv->{pattern}}
               : ( $argv->{pattern} );

  my $failure = 0;
  local $@;
  eval {
    for my $pattern ( @patterns ) {
      if (! grep m{$pattern}, @contents) {
        $self->fail("$argv->{path} don't have line $pattern");
        $failure++;
      }
    }
  };
  warn $@ if $@;

  return $failure == 0;

}

1; # End of Roccaku::Run::Must;
