package Roccaku::Utils;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);
use Sys::Hostname;

our $SYSLOG_FACILITY = q{local1};
our $SYSLOG_LEVEL    = q{info};

our $__GEN_SORT = 10;

sub import {
  my $caller = caller;
  no strict 'refs';
  no warnings 'redefine';
  *{"${caller}::logging"}     = \&logging;
  *{"${caller}::server_info"} = \&server_info;
}

sub logging {

  my ($string, $stderr) = @_;
  $string ||= qq{};

  openlog __FILE__, q{ndelay,pid}, $SYSLOG_FACILITY;
  setlogsock 'unix';
  syslog $SYSLOG_LEVEL, qq{$string};
  closelog;
  print {*STDERR} "$string\n" if $stderr and $string;

}


sub server_info {
  +{
     hostname => hostname,
     ip       => get_ip(),
  };
}

sub get_ip {
  open my $pipe, "/sbin/ifconfig -a |";
  my @ips;
  while (my $line = <$pipe>) {
    $line =~ /\s+inet\saddr:(\S+)/
      and push @ips, $1;
  }
  close $pipe;
  return \@ips;
}

1; # End of Roccaku::Utils;
