package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);
use Data::Dumper;
use POSIX qw(strftime);
use Carp;
use IPC::Open3;

use FindBin;
use lib qq($FindBin::Bin/../lib);
use Roccaku::Utils ();

our $__GEN_SORT = 20;
our $__RESULT = +{
                   fail   => 0,
                   ok     => 0,
                   number => 0,
                };

our $__NOT_MODE;

sub __result {
  my ($self, $name, $num) = @_;
  $num ||= 1;
  $__RESULT->{$name} += $num;
}

sub add_number {
  shift->__result( q{number}, shift );
}

sub add_ok {
  shift->__result( q{ok}, shift );
}

sub add_fail {
  shift->__result( q{fail}, shift );
}

sub result { $__RESULT; }

sub new {
  my ($class, $params, $option) = @_;

  my $obj = bless +{ fail => [] }, $class;
  $obj->params( $params );
  $obj->option( $option );

  return $obj;
}

sub run {
  my ($self) = @_;

  my $params = $self->params;

  my @args = ref $params eq q{ARRAY}
           ? @$params
           : $params;

  my @results = $self->favor( @args );

  my @fails = $self->fail;
  if (@fails > 0) {
    # if api_mode is true, no output to stderr
    $self->logging("\t[FAIL]: $_") for @fails;
  }
  return @results if wantarray;
  return $results[0];

}

sub params {
  my ($self, $params) = @_;
  if (defined $params) {
    $self->{params} = $params;
  }
  return $self->{params};
}

sub option {
  my ($self, $option) = @_;
  if (defined $option) {
    $self->{option} = $option
  }
  return $self->{option};
}

sub favor {
  croak "Do nothing";
}

sub command {
  my ($self, $command) = @_;
  my ($w, $r, $e);
  $command ||= "/bin/false";
  logging("[try to exec]: $command");
  my $pid = open3 $w, $r, $e, $command; # It might have a deadlock problem

  if ($pid != 0) {
    waitpid $pid, 0;
    my $exit_code = $? >> 8;

    my $stderr = do { local $/; defined $e and <$e> };
    my $stdout = do { local $/; defined $r and <$r> };

    $self->logging( $stdout ) if $stdout and $self->debug;
    $stdout ||= qq{none};
    $stderr ||= qq{none};

    if ($exit_code != 0 and not $__NOT_MODE) {
      $self->fail( "command: $command (stderr: $stderr)" );
      return undef;
    }

    return 1;
  }
}

sub file_backup {
  my ($self, @files) = @_;
  my $datetime = strftime "%Y%m%d%H%M%S", localtime;
  my @fails;
  for my $f ( @files ) {
    ( defined $f and -f $f ) or next;
    my $r = system "cp -p $f ${f}.$datetime";
    if ($r != 0) {
      push @fails, +{ file => $f, exit_code => $? };
    }
  }
  warn Dumper \@fails if @fails > 0;
  return @fails == 0;
}

sub fail {
  my $self  = shift;
  my @fails = @_;

  if (@fails > 0) {
    push @{$self->{fail}}, @fails;
  }

  return @{$self->{fail}} if wantarray;
  return   $self->{fail};
}

sub logging {
  my $self     = shift;
  my $string   = shift;
  no strict 'refs';
  my $api_mode = $self->{option}->{api_mode} ? 1 : 0;
  Roccaku::Utils::logging( $string, not $api_mode );
}

our $AUTOLOAD;
sub AUTOLOAD {
  my ($method) = $AUTOLOAD =~ /::([^(?:::)]+)$/;
  no strict 'refs';
  *{$AUTOLOAD} = sub {
    my $self = shift;
    my $argv = shift;
    if (defined $argv) {
      $self->{option}->{$method} = $argv;
    }
    return $self->{option}->{$method} || undef;
  };
  goto &$AUTOLOAD;
}

sub DESTROY {}

1; # End of Roccaku
