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
  return _create_env_string( $self->{env} );
}

sub _create_env_string {
  my ($hash_ref) = @_;
  my $env = qq{};
  if (exists $hash_ref->{PATH}) {
    $hash_ref->{PATH} = _get_wrapper_path() . ":$hash_ref->{PATH}";
  } else {
    $hash_ref->{PATH} = _get_wrapper_path() . ":$ENV{PATH}";
  }
  while (my ($key, $value) = each %$hash_ref) {
    $env and $env .= qq{ };
    $env .= qq{${key}=$value};
  }
  return $env;
}

sub _get_wrapper_path {
  return qq{$FindBin::Bin/../wrapper};
}

1; # End of Roccaku::Env;
