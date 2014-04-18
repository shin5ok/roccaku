package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use File::Temp;
use lib  qq($FindBin::Bin/../lib);

use Roccaku::Utils;

my $sudo = qq{};

our $temporary_working_base = q{/var/tmp};

sub run {
  my ($self, $host, $command_argv) = @_;
  my $temporary_working_dir = _gen_working_dir();
  my $scp = "$sudo scp -r $path/ $host:$temporary_working_dir/$path";
  my $run = sprintf "$sudo ssh %s %s/bin/roccaku %s",
                 $host,
                 $path,
                 ( join " ", @$command_argv );
  logging $scp;
  system $scp;
  logging $run;
  system $run;
  system "rm -Rf $temporary_working_dir";
}

sub _gen_working_dir {
  my $name = `uuidgen`;
  chomp $name;
  sprintf "%s/%s", $temporary_working_base, $name;
}

1; # End of Roccaku::Say;
