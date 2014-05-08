package Roccaku::Env;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;

our $env = qq{};

sub new {
  my ($class, $hash_ref) = @_;
  $hash_ref ||= {};
  bless {
    env => $hash_ref,
  }, $class;
}

sub env_string {
  my ($self) = @_;
  return _create_env_string( $hash_ref );
}

sub _create_env_string {
  my ($hash_ref) = @_;
  my $env = qq{};
  while (my ($key, $value) = each %$hash_ref) {
    $env and $env .= qq{ };
    $env .= qq{${key}=$value};
  }
  return $env;
}

1; # End of Roccaku::Env;
