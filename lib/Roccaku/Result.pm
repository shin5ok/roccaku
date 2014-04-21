package Roccaku::Result;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use JSON::PP;
use FindBin;
use lib (qq($FindBin::Bin/../lib), qq($FindBin::Bin/../extlib));

use Roccaku::Utils;

our $template_path = qq{};

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

sub text_template {
  require Template;
  my $tt = Template->new;
  $tt->process( $template_path, $self->result );

}

1; # End of Roccaku::Result;
