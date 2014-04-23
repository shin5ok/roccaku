package Roccaku::Run::Say;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use base qw( Roccaku::Run::Base );

our $__GEN_SORT = 50;

our $SAY_NUMBER = 0;

sub favor {
  my ($self, @strings) = @_;

  my @says;
  for my $string ( @strings ) {
    my $string_formatted = sprintf "%5d: $string", ++$SAY_NUMBER;
    $self->logging( $string_formatted );
  }
  return $says[0] if @says == 1;
  return \@says;
}

1; # End of Roccaku::Say;
