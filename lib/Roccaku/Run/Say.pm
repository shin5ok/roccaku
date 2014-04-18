package Roccaku::Run::Say;

use 5.006;
use strict;
use warnings FATAL => 'all';

use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use base qw( Roccaku::Run::Base );

our $SAY_NUMBER = 0;

sub favor {
  my ($self, @strings) = @_;

  for my $string ( @strings ) {
    $SAY_NUMBER++;
    printf "%5d: %s\n", $SAY_NUMBER, $string;
  }

}

1; # End of Roccaku::Say;
