package Roccaku::Run::Env;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use base qw( Roccaku::Run::Base );

our $__GEN_SORT = 50;
our $env = qq{};

sub run {
  my ($self) = @_;
}

sub env {

}

1; # End of Roccaku::Run::Env;
