package Roccaku::Result;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use FindBin;
use lib (qq($FindBin::Bin/../lib), qq($FindBin::Bin/../extlib));
use JSON::PP;

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
  return encode_json ( $self->result );
}

sub result {
  my ($self, $result) = @_;
  if (defined $result) {
     $self->{result} = $result,
  }
  return $self->{result};
}

sub text_template {
  my ($self, $template_path) = @_;
  $template_path ||= qq{$FindBin::Bin/../template/default.tt};
  require Template;
  my $tt = Template->new( { RELATIVE => 1 } );
  $tt->process( $template_path, $self->result );

}

1; # End of Roccaku::Result;
