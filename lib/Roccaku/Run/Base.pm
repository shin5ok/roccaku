package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);
use Data::Dumper;
use Carp;
use IPC::Open3;

our $SYSLOG_FACILITY = q{local1};
our $SYSLOG_LEVEL    = q{info};

sub new {
  my ($class, $params) = @_;

  my $obj = bless +{ fail => [] }, $class;
  $obj->params( $params );

  return $obj;
}

sub run {
  my ($self) = @_;

  my $params = $self->params;

  my @args = ref $params eq q{ARRAY}
           ? @$params
           : $params;

  $self->favor( @args );

  my $fail_ref = $self->fail;
  if (@$fail_ref > 0) {
    $self->logging("[FAILURE]: $_", "__STDERR__") for @$fail_ref;
    return 0;
  }
  return 1;

}

sub logging {
  my ($self, $string, $stderr) = @_;
  openlog __FILE__, q{ndelay,pid}, $SYSLOG_FACILITY;
  setlogsock 'unix';
  syslog $SYSLOG_LEVEL, qq{$string};
  closelog;
  warn "\t$string" if $stderr;

}

sub params {
  my ($self, $params) = @_;
  if (defined $params) {
    $self->{params} = $params;
  }
  return $self->{params};
}

sub favor {
  croak "Do nothing";
}

sub command {
  my ($self, $command) = @_;
  my ($w, $r, $e);
  $command ||= "";
  $self->logging("[try to exec]: $command");
  my $pid = open3 $w, $r, $e, $command; # It might have a deadlock problem

  if ($pid != 0) {
    waitpid $pid, 0;
    my $exit_code = $? >> 8;

    if ($exit_code != 0) {
      $e ||= qq{NONE};
      $self->fail( "command: $command (output: $e)" );
      return undef;
    }

    return 1;
  }
}

sub fail {
  my $self  = shift;
  my @fails = @_;

  my $caller = caller;
  if (@fails > 0) {
    push @{$self->{fail}}, map { "$caller: $_" } @fails;
  }

  return $self->{fail};
}

1; # End of Roccaku
