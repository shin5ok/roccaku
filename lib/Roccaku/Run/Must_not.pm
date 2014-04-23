package Roccaku::Run::Must_not;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Must;
use base qw( Roccaku::Run::Must );

our $__GEN_SORT = 51;

sub favor {
  my ($self, @args) = @_;
  ! $self->SUPER::favor( @args );
}

sub file {
  my ($self, $argv) = @_;
  ! $self->SUPER::file( $argv );
}

1; # End of Roccaku::Must_not;
