package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

sub new {
  my $class = shift;
  bless {}, $class;
}

1; # End of Roccaku
