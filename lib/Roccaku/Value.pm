package Roccaku::Value;

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
    value => _create_value_hash( $hash_ref ),
  }, $class;
}

sub _create_value_hash {
  my ($hash_ref) = @_;
  my $ref = qq{};
  while (my ($key, $value) = each %$hash_ref) {
    if ($value =~ m{\`(.+)\`}) {
      chomp ( $value = qx{$1} );
      $ref->{$key} = $value;
    }
  }
  return $ref;
}

1; # End of Roccaku::Value;
