package Roccaku::Run::Must;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Digest::MD5 qw(md5_hex);
use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use base qw( Roccaku::Run::Base );

our $__GEN_SORT = 50;

sub favor {
  my ($self, @args) = @_;

  for my $arg ( @args ) {
    if (ref $arg eq q{HASH}) {
      while (my ($method, $value) = each %$arg) {
        $self->$method( $value );
      }
    } else {
      $self->command( $arg );
    }
  }
}

sub file {
  my ($self, $argv) = @_;
  my $fh;
  if (! open $fh, "<", $argv->{path}) {
    $self->fail("$argv->{path} cannot open");
    return 0;
  }

  my @contents = <$fh>;
  if (exists $argv->{same}) {
    my $data1 = _get_md5_hex( join "", @contents    );
    my $data2 = _get_md5_hex( _get_data( $argv->{is_same} ) );
    return $data1 eq $data2;
  }

  my @patterns = ref $argv->{pattern} eq q{ARRAY}
               ? @{$argv->{pattern}}
               : ( $argv->{pattern} );

  my $failure = 0;
  local $@;
  eval {
    for my $pattern ( @patterns ) {
      my $pattern_compiled = qr/$pattern/;
      if (! grep { /$pattern_compiled/ } @contents) {
        $self->fail("$argv->{path} don't have line $pattern");
        $failure++;
      }
    }
  };
  warn $@ if $@;

  return $failure == 0;

}

sub _get_md5_hex {
  my $data = shift;
  return md5_hex $data;
}

sub _get_data {
  my $file = shift;
  if ($file =~ m{^([^:]+):(/.+)}) {
    my @datas = qx{ssh $1 cat $2};
    return join "", @datas;
  } else {
    open my $fh, "<", $file
      or return qq{};
    my @datas = <$fh>;
    return join "", @datas;
  }
}

1; # End of Roccaku::Run::Must;
