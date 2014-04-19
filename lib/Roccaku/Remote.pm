package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use FindBin;
use File::Spec;
use File::Basename;
use lib qq($FindBin::Bin/../lib);

use Roccaku::Utils;

our $sudo = qq{};

our $temporary_working_base = q{/var/tmp};

sub run {
  my ($host, $command_argv) = @_;
  my $temporary_working_dir = _gen_working_dir();
  my $path = exists $ENV{ROCCAKU_ROOT_PATH}
           ? $ENV{ROCCAKU_ROOT_PATH}
           : qq{$ENV{HOME}/roccaku};

  my $scp = "scp -r $path/ $host:$temporary_working_dir/$path";
  my $run = sprintf "ssh %s $sudo %s/bin/roccaku %s",
                     $host,
                     $path,
                     ( join " ", @$command_argv );
  my $rmd = "ssh $host rm -Rf $temporary_working_dir";

  my @cmds;
  push @cmds, ( qq{$scp}, qq{$run}, qq{$rmd} );

  for my $cmd ( @cmds ) {
    my $r = (system $cmd) == 0
          ? "ok"
          : "ERROR";

    logging "$r: $cmd";
  }
}

sub _gen_working_dir {
  my $uuid = `uuidgen 2> /dev/null`;
  chomp $uuid;
  $uuid ||= strftime "%Y%m%d%H%M%S", localtime;
  sprintf "%s/.%s_%s", $temporary_working_base, ( basename __FILE__) , $uuid;
}

1; # End of Roccaku::Say;
