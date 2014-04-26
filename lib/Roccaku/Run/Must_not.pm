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
  local $Roccaku::Run::Base::__NOT_MODE = 1;
  return shift->SUPER::favor( @_ );
}

sub file {
  local $Roccaku::Run::Base::__NOT_MODE = 1;
  return shift->SUPER::file( @_ );
}

1; # End of Roccaku::Run::Must_not;
