package Roccaku::Run::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);
use Data::Dumper;
use POSIX qw(strftime);
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

  my @fails = $self->fail;
  if (@fails > 0) {
    $self->logging("[FAIL]: $_", "__STDERR__") for @fails;
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
  print {*STDERR} "\t$string\n" if $stderr;

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
  $command ||= "/bin/false";
  $self->logging("[try to exec]: $command");
  my $pid = open3 $w, $r, $e, $command; # It might have a deadlock problem

  if ($pid != 0) {
    waitpid $pid, 0;
    my $exit_code = $? >> 8;

    if ($exit_code != 0) {
      my $stderr = do { local $/; defined $e and <$e> };
      my $stdout = do { local $/; defined $r and <$r> };

      $stdout ||= qq{};
      $stderr ||= qq{};
      $self->logging( $stdout );
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

1; # End of Roccaku
