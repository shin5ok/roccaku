package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);
use Data::Dumper;

sub new {
  my ($class, $argv) = @_;

  my $obj = bless +{}, $class;
  $obj->params( $argv );

  return $obj;
}

sub logging {
  my ($self, $string) = @_;

}

sub params {
  my ($self, $params) = @_;
  if ($argv) {
    $self->{params} = $params;
  }
  return $params;
}

1; # End of Roccaku
