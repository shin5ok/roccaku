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

}

sub logging {
  my ($self, $string) = @_;
  openlog __FILE__, q{ndelay,pid}, $SYSLOG_FACILITY;
  setlogsock 'unix';
  syslog $SYSLOG_LEVEL, qq{$string};
  closelog;

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

  if ($pid != 0){
    waitpid $pid, 0;
    my $exit_code = $? >> 8;

    if ($exit_code != 0) {
      $self->logging( $e || qq{} );
      return undef;
    }

    return 1;
  }
}

sub fail {
  my $self  = shift;
  my @fails = @_;

  if (@fails > 0) {
    push @{$self->{fail}}, @fails;
  }

  return $self->{fail};
}

1; # End of Roccaku
