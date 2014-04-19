package Roccaku::Result;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use JSON::PP;
use YAML::Tiny;
use FindBin;
use lib qq($FindBin::Bin/../lib);

use Roccaku::Utils;

sub new {
  my ($class, $result) = @_;
  bless {
    result => $result || undef,
  }, $class;
}

sub json {
  my $self = shift;
  return decode_json $self->result;
}

sub result {
  my ($self, $result) = @_;
  if (defined $result) {
     $self->{result} = $result,
  }
  return $self->{result};
}

1; # End of Roccaku::Result;
