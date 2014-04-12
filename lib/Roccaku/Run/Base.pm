package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;

sub new {
  my ($class, @argv) = @_;
  # warn Dumper \@argv;
  bless {}, $class;
}

sub logging {

}

1; # End of Roccaku
