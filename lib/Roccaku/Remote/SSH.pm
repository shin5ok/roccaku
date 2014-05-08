package Roccaku::Remote::SSH;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use FindBin;
use File::Basename;
use File::Spec;
use Carp;
use lib qq($FindBin::Bin/../lib);

sub run {
  return;
  my ($host) = @_;
  local $?;
  qx{which ssh-copy-id};
  if ($? != 0) {
    croak "ssh-copy-id cannot be find";
  }

}

1; # End of Roccaku::Remote::SSH;
