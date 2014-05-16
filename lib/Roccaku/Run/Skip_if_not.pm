package Roccaku::Run::Skip_if_not;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Must;
use base qw( Roccaku::Run::Must );

our $__GEN_SORT = 52;

local $Roccaku::Run::Skip_if_not::__NOT_LOG = 1;

1; # End of Roccaku::Run::Skip_if_not;
