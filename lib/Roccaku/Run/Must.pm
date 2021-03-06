package Roccaku::Run::Must;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Digest::MD5 qw(md5_hex);
use FindBin;
use lib  qq($FindBin::Bin/../lib);
use Roccaku::Run::Base;
use Roccaku::File;
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

  my $failure = 0;
  if (exists $argv->{same} or exists $argv->{same_as}) {

    my $same = $argv->{same} || $argv->{same_as};
    if ($same =~ m{^([^\:]+\:)\-$}) {
      $same  = $1;
      $same .= $argv->{path};
    }

    my $as = exists $argv->{same_as} ? $argv->{same_as} : 0;

    my $data1 = _get_md5_hex( join "", @contents );
    my $data2 = _get_md5_hex( Roccaku::File::get_data( $same,
                                                        { as => $as },
                                                      ) );

    if ($data1 ne $data2) {
      if (! $Roccaku::Run::Base::__NOT_MODE) {
        $self->fail("$argv->{path}($data1) and $same($data2) are different file");
        $failure++;
      }
    }

  } else {

    my @patterns = ref $argv->{pattern} eq q{ARRAY}
                 ? @{$argv->{pattern}}
                 : ( $argv->{pattern} );

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
  }

  warn $@ if $@;
  return $failure == 0;

}

sub _get_md5_hex {
  my $data = shift;
  return md5_hex $data;
}

1; # End of Roccaku::Run::Must;
