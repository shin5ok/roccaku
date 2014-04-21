package Roccaku::Utils;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Sys::Syslog qw(:DEFAULT setlogsock);

our $SYSLOG_FACILITY = q{local1};
our $SYSLOG_LEVEL    = q{info};

our $__GEN_SORT = 10;

sub import {
  my $caller = caller;
  no strict 'refs';
  no warnings 'redefine';
  *{"${caller}::logging"} = \&logging;
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

1; # End of Roccaku::Utils;
